alter table public.rooms
  add column if not exists preferred_board_id uuid references public.word_boards(id);

create or replace function public.update_room_settings(
  target_room_code text,
  requesting_player_id uuid,
  preferred_board_id uuid,
  round_duration_seconds integer
)
returns public.rooms
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room public.rooms%rowtype;
  updated_room public.rooms%rowtype;
begin
  if $4 < 30 or $4 > 1800 then
    raise exception 'Timer must be between 30 seconds and 30 minutes.';
  end if;

  select * into target_room
  from public.rooms r
  where r.room_code = upper(trim(target_room_code))
  for update;

  if target_room.id is null then
    raise exception 'Room not found.';
  end if;

  if target_room.host_player_id <> requesting_player_id then
    raise exception 'Only the host can update room settings.';
  end if;

  if target_room.status = 'playing' then
    raise exception 'Settings can only be changed between rounds.';
  end if;

  if $3 is not null and not exists (
    select 1 from public.word_boards wb where wb.id = $3 and wb.is_active
  ) then
    raise exception 'Selected theme is unavailable.';
  end if;

  update public.rooms r
  set preferred_board_id = $3,
      round_duration_seconds = $4
  where r.id = target_room.id
  returning * into updated_room;

  return updated_room;
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

  if target_room.preferred_board_id is not null then
    select * into selected_board
    from public.word_boards wb
    where wb.id = target_room.preferred_board_id
      and wb.is_active;
  else
    select * into selected_board
    from public.word_boards wb
    where wb.is_active
    order by random()
    limit 1;
  end if;

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

grant execute on function public.update_room_settings(text, uuid, uuid, integer) to anon, authenticated;

insert into public.word_boards (slug, category, board_data) values
('sports', 'Sports', '{
  "A1":"Soccer","A2":"Tennis","A3":"Basketball","A4":"Baseball","A5":"Swimming","A6":"Running",
  "B1":"Cycling","B2":"Boxing","B3":"Golf","B4":"Hockey","B5":"Rugby","B6":"Volleyball",
  "C1":"Cricket","C2":"Badminton","C3":"Skateboarding","C4":"Surfing","C5":"Skiing","C6":"Climbing",
  "D1":"Gymnastics","D2":"Archery","D3":"Fencing","D4":"Bowling","D5":"Wrestling","D6":"Rowing",
  "E1":"Karate","E2":"Diving","E3":"Table Tennis","E4":"Marathon","E5":"Snowboarding","E6":"Formula One"
}'::jsonb),
('music', 'Music', '{
  "A1":"Guitar","A2":"Piano","A3":"Drums","A4":"Violin","A5":"Saxophone","A6":"Trumpet",
  "B1":"Microphone","B2":"Concert","B3":"Choir","B4":"Orchestra","B5":"Melody","B6":"Rhythm",
  "C1":"Bass","C2":"Flute","C3":"Ukulele","C4":"Harp","C5":"DJ","C6":"Album",
  "D1":"Playlist","D2":"Festival","D3":"Opera","D4":"Jazz","D5":"Rock","D6":"Pop",
  "E1":"Hip Hop","E2":"Classical","E3":"Karaoke","E4":"Studio","E5":"Encore","E6":"Lyrics"
}'::jsonb),
('jobs', 'Jobs', '{
  "A1":"Doctor","A2":"Teacher","A3":"Chef","A4":"Pilot","A5":"Engineer","A6":"Nurse",
  "B1":"Artist","B2":"Lawyer","B3":"Dentist","B4":"Firefighter","B5":"Mechanic","B6":"Scientist",
  "C1":"Writer","C2":"Designer","C3":"Farmer","C4":"Barista","C5":"Plumber","C6":"Electrician",
  "D1":"Architect","D2":"Photographer","D3":"Accountant","D4":"Programmer","D5":"Librarian","D6":"Translator",
  "E1":"Actor","E2":"Dancer","E3":"Journalist","E4":"Security Guard","E5":"Veterinarian","E6":"Cashier"
}'::jsonb),
('technology', 'Technology', '{
  "A1":"Laptop","A2":"Phone","A3":"Tablet","A4":"Keyboard","A5":"Mouse","A6":"Monitor",
  "B1":"Router","B2":"Camera","B3":"Printer","B4":"Headphones","B5":"Charger","B6":"Battery",
  "C1":"Robot","C2":"Drone","C3":"Server","C4":"Website","C5":"App","C6":"Password",
  "D1":"Bluetooth","D2":"WiFi","D3":"Cloud","D4":"Database","D5":"Firewall","D6":"Algorithm",
  "E1":"Speaker","E2":"Touchscreen","E3":"Smartwatch","E4":"Console","E5":"USB","E6":"Browser"
}'::jsonb),
('nature', 'Nature', '{
  "A1":"River","A2":"Mountain","A3":"Forest","A4":"Ocean","A5":"Volcano","A6":"Waterfall",
  "B1":"Canyon","B2":"Meadow","B3":"Lake","B4":"Glacier","B5":"Island","B6":"Valley",
  "C1":"Thunder","C2":"Rainbow","C3":"Sunrise","C4":"Sunset","C5":"Cloud","C6":"Rain",
  "D1":"Flower","D2":"Tree","D3":"Mushroom","D4":"Moss","D5":"Coral","D6":"Sand",
  "E1":"Pebble","E2":"Leaf","E3":"Star","E4":"Moon","E5":"Cave","E6":"Cliff"
}'::jsonb),
('household', 'Household', '{
  "A1":"Sofa","A2":"Table","A3":"Chair","A4":"Lamp","A5":"Mirror","A6":"Curtain",
  "B1":"Fridge","B2":"Oven","B3":"Sink","B4":"Kettle","B5":"Toaster","B6":"Microwave",
  "C1":"Pillow","C2":"Blanket","C3":"Towel","C4":"Soap","C5":"Shampoo","C6":"Toothbrush",
  "D1":"Broom","D2":"Vacuum","D3":"Laundry","D4":"Closet","D5":"Shelf","D6":"Carpet",
  "E1":"Remote","E2":"Clock","E3":"Candle","E4":"Plant","E5":"Doorbell","E6":"Keys"
}'::jsonb),
('travel', 'Travel', '{
  "A1":"Passport","A2":"Suitcase","A3":"Hotel","A4":"Taxi","A5":"Train","A6":"Airplane",
  "B1":"Ticket","B2":"Map","B3":"Beach","B4":"Temple","B5":"Museum","B6":"Bridge",
  "C1":"Souvenir","C2":"Backpack","C3":"Hostel","C4":"Cruise","C5":"Tour","C6":"Guide",
  "D1":"Market","D2":"Airport","D3":"Station","D4":"Ferry","D5":"Hiking","D6":"Camping",
  "E1":"Currency","E2":"Postcard","E3":"Border","E4":"Resort","E5":"Landmark","E6":"Road Trip"
}'::jsonb),
('games', 'Games', '{
  "A1":"Dice","A2":"Cards","A3":"Chess","A4":"Puzzle","A5":"Controller","A6":"Score",
  "B1":"Level","B2":"Boss","B3":"Quest","B4":"Token","B5":"Board","B6":"Rulebook",
  "C1":"Avatar","C2":"Inventory","C3":"Power-Up","C4":"Joystick","C5":"Checkpoint","C6":"Leaderboard",
  "D1":"Strategy","D2":"Bluffing","D3":"Treasure","D4":"Dungeon","D5":"Mini Game","D6":"Speedrun",
  "E1":"Tournament","E2":"Co-op","E3":"Lobby","E4":"Match","E5":"Victory","E6":"Game Over"
}'::jsonb)
on conflict (slug) do update
set category = excluded.category,
    board_data = excluded.board_data,
    is_active = true;
