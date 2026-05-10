create extension if not exists pgcrypto;

create or replace function public.jsonb_object_key_count(value jsonb)
returns integer
language sql
immutable
as $$
  select count(*)::integer from jsonb_object_keys(value);
$$;

create table public.word_boards (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  category text not null,
  board_data jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint word_boards_has_30_cells check (public.jsonb_object_key_count(board_data) = 30)
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  room_code text not null unique check (room_code ~ '^[A-Z2-9]{4,6}$'),
  status text not null default 'waiting' check (status in ('waiting', 'playing', 'ended')),
  host_player_id uuid,
  selected_board_id uuid references public.word_boards(id),
  selected_coordinate text check (selected_coordinate is null or selected_coordinate ~ '^[A-E][1-6]$'),
  selected_word text,
  chameleon_player_id uuid,
  timer_started_at timestamptz,
  round_duration_seconds integer not null default 180 check (round_duration_seconds between 30 and 1800),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 40),
  is_host boolean not null default false,
  role text check (role in ('common', 'chameleon')),
  joined_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

alter table public.rooms
  add constraint rooms_host_player_fk
  foreign key (host_player_id) references public.players(id) deferrable initially deferred;

alter table public.rooms
  add constraint rooms_chameleon_player_fk
  foreign key (chameleon_player_id) references public.players(id) deferrable initially deferred;

create index rooms_room_code_idx on public.rooms (room_code);
create index rooms_status_idx on public.rooms (status);
create index players_room_id_joined_at_idx on public.players (room_id, joined_at);
create index word_boards_is_active_idx on public.word_boards (is_active);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger touch_rooms_updated_at
before update on public.rooms
for each row execute function public.touch_updated_at();

create trigger touch_word_boards_updated_at
before update on public.word_boards
for each row execute function public.touch_updated_at();

create or replace function public.generate_room_code()
returns text
language plpgsql
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i integer;
begin
  for i in 1..5 loop
    result := result || substr(alphabet, 1 + floor(random() * length(alphabet))::integer, 1);
  end loop;

  return result;
end;
$$;

create or replace function public.create_room(host_name text)
returns table (room_id uuid, room_code text, player_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_name text := trim(host_name);
  new_room_id uuid;
  new_room_code text;
  new_player_id uuid;
begin
  if clean_name = '' or char_length(clean_name) > 40 then
    raise exception 'Enter a host name between 1 and 40 characters.';
  end if;

  loop
    new_room_code := public.generate_room_code();
    exit when not exists (select 1 from public.rooms r where r.room_code = new_room_code);
  end loop;

  insert into public.rooms (room_code)
  values (new_room_code)
  returning id into new_room_id;

  insert into public.players (room_id, name, is_host)
  values (new_room_id, clean_name, true)
  returning id into new_player_id;

  update public.rooms
  set host_player_id = new_player_id
  where id = new_room_id;

  return query select new_room_id, new_room_code, new_player_id;
end;
$$;

create or replace function public.join_room(join_code text, player_name text)
returns table (room_id uuid, room_code text, player_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_code text := upper(trim(join_code));
  clean_name text := trim(player_name);
  target_room public.rooms%rowtype;
  new_player_id uuid;
begin
  if clean_name = '' or char_length(clean_name) > 40 then
    raise exception 'Enter a player name between 1 and 40 characters.';
  end if;

  select * into target_room
  from public.rooms r
  where r.room_code = clean_code;

  if target_room.id is null then
    raise exception 'Room not found. Check the code and try again.';
  end if;

  if target_room.status <> 'waiting' then
    raise exception 'This room already started. Create a new room to play.';
  end if;

  insert into public.players (room_id, name, is_host)
  values (target_room.id, clean_name, false)
  returning id into new_player_id;

  return query select target_room.id, target_room.room_code, new_player_id;
end;
$$;

create or replace function public.start_round(target_room_code text, requesting_player_id uuid)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room public.rooms%rowtype;
  player_count integer;
  selected_chameleon uuid;
  selected_board public.word_boards%rowtype;
  coordinates constant text[] := array[
    'A1','A2','A3','A4','A5','A6',
    'B1','B2','B3','B4','B5','B6',
    'C1','C2','C3','C4','C5','C6',
    'D1','D2','D3','D4','D5','D6',
    'E1','E2','E3','E4','E5','E6'
  ];
  selected_coord text;
  updated_room public.rooms%rowtype;
begin
  select * into target_room
  from public.rooms r
  where r.room_code = upper(trim(target_room_code))
  for update;

  if target_room.id is null then
    raise exception 'Room not found.';
  end if;

  if target_room.host_player_id <> requesting_player_id then
    raise exception 'Only the host can start the round.';
  end if;

  select count(*) into player_count
  from public.players p
  where p.room_id = target_room.id;

  if player_count < 3 then
    raise exception 'At least 3 players are required to start.';
  end if;

  select p.id into selected_chameleon
  from public.players p
  where p.room_id = target_room.id
  order by random()
  limit 1;

  select * into selected_board
  from public.word_boards wb
  where wb.is_active
  order by random()
  limit 1;

  if selected_board.id is null then
    raise exception 'No active word boards are available.';
  end if;

  selected_coord := coordinates[1 + floor(random() * array_length(coordinates, 1))::integer];

  update public.players p
  set role = case when p.id = selected_chameleon then 'chameleon' else 'common' end
  where p.room_id = target_room.id;

  update public.rooms r
  set status = 'playing',
      selected_board_id = selected_board.id,
      selected_coordinate = selected_coord,
      selected_word = selected_board.board_data ->> selected_coord,
      chameleon_player_id = selected_chameleon,
      timer_started_at = now()
  where r.id = target_room.id
  returning * into updated_room;

  return updated_room;
end;
$$;

create or replace function public.reveal_result(target_room_code text, requesting_player_id uuid)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_room public.rooms%rowtype;
begin
  update public.rooms r
  set status = 'ended'
  where r.room_code = upper(trim(target_room_code))
    and r.host_player_id = requesting_player_id
  returning * into updated_room;

  if updated_room.id is null then
    raise exception 'Only the host can reveal the result.';
  end if;

  return updated_room;
end;
$$;

alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.word_boards enable row level security;

create policy "Anyone can read active word boards"
on public.word_boards for select
using (is_active);

create policy "Anyone can read rooms for MVP"
on public.rooms for select
using (true);

create policy "Anyone can read players for MVP"
on public.players for select
using (true);

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;

grant usage on schema public to anon, authenticated;
grant select on public.word_boards, public.rooms, public.players to anon, authenticated;
revoke insert, update, delete on public.word_boards, public.rooms, public.players from anon, authenticated;
grant execute on function public.create_room(text) to anon, authenticated;
grant execute on function public.join_room(text, text) to anon, authenticated;
grant execute on function public.start_round(text, uuid) to anon, authenticated;
grant execute on function public.reveal_result(text, uuid) to anon, authenticated;

insert into public.word_boards (slug, category, board_data) values
('food', 'Food', '{
  "A1":"Pizza","A2":"Sushi","A3":"Burger","A4":"Pasta","A5":"Ramen","A6":"Taco",
  "B1":"Curry","B2":"Hotpot","B3":"Laksa","B4":"Noodles","B5":"Steak","B6":"Salad",
  "C1":"Dumpling","C2":"Falafel","C3":"Waffle","C4":"Pancake","C5":"Burrito","C6":"Paella",
  "D1":"Pho","D2":"Kebab","D3":"Risotto","D4":"Bagel","D5":"Donut","D6":"Gelato",
  "E1":"Brownie","E2":"Nachos","E3":"Omelet","E4":"Kimchi","E5":"Lasagna","E6":"Croissant"
}'::jsonb),
('animals', 'Animals', '{
  "A1":"Tiger","A2":"Penguin","A3":"Koala","A4":"Giraffe","A5":"Otter","A6":"Panda",
  "B1":"Dolphin","B2":"Eagle","B3":"Fox","B4":"Kangaroo","B5":"Lion","B6":"Moose",
  "C1":"Octopus","C2":"Rabbit","C3":"Shark","C4":"Turtle","C5":"Whale","C6":"Zebra",
  "D1":"Badger","D2":"Camel","D3":"Flamingo","D4":"Gorilla","D5":"Hamster","D6":"Iguana",
  "E1":"Jaguar","E2":"Lemur","E3":"Narwhal","E4":"Owl","E5":"Hedgehog","E6":"Sloth"
}'::jsonb),
('movies', 'Movies', '{
  "A1":"Titanic","A2":"Jaws","A3":"Frozen","A4":"Avatar","A5":"Rocky","A6":"Grease",
  "B1":"Shrek","B2":"Up","B3":"Cars","B4":"Coco","B5":"Moana","B6":"Dune",
  "C1":"Alien","C2":"Psycho","C3":"Casablanca","C4":"Matilda","C5":"Twister","C6":"Godzilla",
  "D1":"Mulan","D2":"Aladdin","D3":"WALL-E","D4":"Ratatouille","D5":"Inception","D6":"Interstellar",
  "E1":"Batman","E2":"Superman","E3":"Spider-Man","E4":"Gladiator","E5":"Minions","E6":"Paddington"
}'::jsonb),
('places', 'Places', '{
  "A1":"Paris","A2":"Tokyo","A3":"London","A4":"Cairo","A5":"Sydney","A6":"Rome",
  "B1":"Berlin","B2":"Dubai","B3":"Toronto","B4":"Boston","B5":"Chicago","B6":"Seattle",
  "C1":"Beach","C2":"Museum","C3":"Airport","C4":"Castle","C5":"Desert","C6":"Forest",
  "D1":"Island","D2":"Market","D3":"Mountain","D4":"Park","D5":"School","D6":"Stadium",
  "E1":"Theater","E2":"Village","E3":"Zoo","E4":"Harbor","E5":"Library","E6":"Cafe"
}'::jsonb),
('school', 'School', '{
  "A1":"Pencil","A2":"Notebook","A3":"Backpack","A4":"Teacher","A5":"Homework","A6":"Quiz",
  "B1":"Science","B2":"Math","B3":"History","B4":"Art","B5":"Music","B6":"Recess",
  "C1":"Cafeteria","C2":"Locker","C3":"Desk","C4":"Ruler","C5":"Eraser","C6":"Marker",
  "D1":"Project","D2":"Library","D3":"Gym","D4":"Bus","D5":"Bell","D6":"Grade",
  "E1":"Essay","E2":"Exam","E3":"Principal","E4":"Classroom","E5":"Schedule","E6":"Textbook"
}'::jsonb)
on conflict (slug) do update
set category = excluded.category,
    board_data = excluded.board_data,
    is_active = true;
