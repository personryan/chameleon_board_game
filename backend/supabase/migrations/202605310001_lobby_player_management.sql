create or replace function public.rename_player(
  target_room_code text,
  requesting_player_id uuid,
  player_name text
)
returns public.players
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_name text := trim(player_name);
  updated_player public.players%rowtype;
begin
  if clean_name = '' or char_length(clean_name) > 40 then
    raise exception 'Enter a player name between 1 and 40 characters.';
  end if;

  update public.players p
  set name = clean_name
  from public.rooms r
  where r.id = p.room_id
    and r.room_code = upper(trim(target_room_code))
    and r.status = 'waiting'
    and p.id = requesting_player_id
  returning p.* into updated_player;

  if updated_player.id is null then
    raise exception 'Names can only be changed in the lobby.';
  end if;

  return updated_player;
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

  if target_room.status <> 'waiting' then
    raise exception 'Players can only be removed from the lobby.';
  end if;

  if target_room.host_player_id <> requesting_player_id then
    raise exception 'Only the host can remove players.';
  end if;

  if target_player_id = target_room.host_player_id then
    raise exception 'The host cannot be removed.';
  end if;

  delete from public.players p
  where p.id = target_player_id
    and p.room_id = target_room.id
  returning p.* into removed_player;

  if removed_player.id is null then
    raise exception 'Player not found in this room.';
  end if;

  return removed_player;
end;
$$;

grant execute on function public.rename_player(text, uuid, text) to anon, authenticated;
grant execute on function public.remove_player(text, uuid, uuid) to anon, authenticated;
