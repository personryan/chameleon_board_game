create or replace function public.cleanup_old_game_sessions(
  retention interval default interval '24 hours'
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_room_count integer;
begin
  if retention < interval '1 hour' then
    raise exception 'Retention must be at least 1 hour.';
  end if;

  delete from public.rooms r
  where r.updated_at < now() - retention;

  get diagnostics deleted_room_count = row_count;
  return deleted_room_count;
end;
$$;

revoke all on function public.cleanup_old_game_sessions(interval) from public;
grant execute on function public.cleanup_old_game_sessions(interval) to postgres;
