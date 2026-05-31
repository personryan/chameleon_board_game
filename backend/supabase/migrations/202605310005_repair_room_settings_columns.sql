alter table public.rooms
  add column if not exists preferred_board_id uuid references public.word_boards(id);

alter table public.rooms
  add column if not exists selected_board_data jsonb;

notify pgrst, 'reload schema';
