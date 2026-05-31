alter table public.players
  add column if not exists is_active boolean not null default true;

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

  if target_room.status = 'playing' then
    raise exception 'Wait for the current round to end before joining.';
  end if;

  insert into public.players (room_id, name, is_host)
  values (target_room.id, clean_name, false)
  returning id into new_player_id;

  return query select target_room.id, target_room.room_code, new_player_id;
end;
$$;

create or replace function public.remove_player(
  target_room_code text,
  requesting_player_id uuid,
  target_player_id uuid
)
returns public.players
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room public.rooms%rowtype;
  removed_player public.players%rowtype;
begin
  select * into target_room
  from public.rooms r
  where r.room_code = upper(trim(target_room_code))
  for update;

  if target_room.id is null then
    raise exception 'Room not found.';
  end if;

  if target_room.host_player_id <> requesting_player_id then
    raise exception 'Only the host can remove players.';
  end if;

  if target_player_id = target_room.host_player_id then
    raise exception 'The host cannot be removed.';
  end if;

  update public.players p
  set is_active = false
  where p.id = target_player_id
    and p.room_id = target_room.id
    and p.is_active
  returning p.* into removed_player;

  if removed_player.id is null then
    raise exception 'Player not found in this room.';
  end if;

  return removed_player;
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
  sampled_board_data jsonb;
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
  where p.room_id = target_room.id
    and p.is_active;

  if player_count < 3 then
    raise exception 'At least 3 players are required to start.';
  end if;

  select p.id into selected_chameleon
  from public.players p
  where p.room_id = target_room.id
    and p.is_active
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

  select jsonb_object_agg(coordinates[numbered.ordinal], numbered.word)
  into sampled_board_data
  from (
    select random_words.word, (row_number() over ())::integer as ordinal
    from (
      select entry.value as word
      from jsonb_each_text(selected_board.board_data) entry
      order by random()
      limit 30
    ) random_words
  ) numbered;

  if public.jsonb_object_key_count(sampled_board_data) <> 30 then
    raise exception 'Selected theme must contain at least 30 words.';
  end if;

  selected_coord := coordinates[1 + floor(random() * array_length(coordinates, 1))::integer];

  update public.players p
  set role = case when p.id = selected_chameleon then 'chameleon' else 'common' end
  where p.room_id = target_room.id
    and p.is_active;

  update public.rooms r
  set status = 'playing',
      selected_board_id = selected_board.id,
      selected_board_data = sampled_board_data,
      selected_coordinate = selected_coord,
      selected_word = sampled_board_data ->> selected_coord,
      chameleon_player_id = selected_chameleon,
      timer_started_at = now()
  where r.id = target_room.id
  returning * into updated_room;

  return updated_room;
end;
$$;

grant execute on function public.join_room(text, text) to anon, authenticated;
grant execute on function public.remove_player(text, uuid, uuid) to anon, authenticated;
