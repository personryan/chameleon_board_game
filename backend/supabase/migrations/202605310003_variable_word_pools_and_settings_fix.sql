alter table public.word_boards
  drop constraint if exists word_boards_has_30_cells;

alter table public.word_boards
  add constraint word_boards_has_at_least_30_cells
  check (public.jsonb_object_key_count(board_data) >= 30);

alter table public.rooms
  add column if not exists preferred_board_id uuid references public.word_boards(id);

alter table public.rooms
  add column if not exists selected_board_data jsonb;

alter table public.rooms
  drop constraint if exists rooms_selected_board_has_30_cells;

alter table public.rooms
  add constraint rooms_selected_board_has_30_cells
  check (
    selected_board_data is null
    or public.jsonb_object_key_count(selected_board_data) = 30
  );

drop function if exists public.update_room_settings(text, uuid, uuid, integer);

create function public.update_room_settings(
  target_room_code text,
  requesting_player_id uuid,
  new_preferred_board_id uuid,
  new_round_duration_seconds integer
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
  if new_round_duration_seconds < 30 or new_round_duration_seconds > 1800 then
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

  if new_preferred_board_id is not null and not exists (
    select 1
    from public.word_boards wb
    where wb.id = new_preferred_board_id
      and wb.is_active
  ) then
    raise exception 'Selected theme is unavailable.';
  end if;

  update public.rooms r
  set preferred_board_id = new_preferred_board_id,
      round_duration_seconds = new_round_duration_seconds
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
  where p.room_id = target_room.id;

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

grant execute on function public.update_room_settings(text, uuid, uuid, integer) to anon, authenticated;

update public.word_boards wb
set board_data = wb.board_data || extras.board_data
from (values
  ('food', '{"F1":"Satay","F2":"Dim Sum","F3":"Bibimbap","F4":"Tiramisu","F5":"Fish and Chips","F6":"Chicken Rice"}'::jsonb),
  ('animals', '{"F1":"Elephant","F2":"Cheetah","F3":"Raccoon","F4":"Parrot","F5":"Platypus","F6":"Meerkat"}'::jsonb),
  ('movies', '{"F1":"Barbie","F2":"The Matrix","F3":"Jurassic Park","F4":"Toy Story","F5":"The Avengers","F6":"Finding Nemo"}'::jsonb),
  ('places', '{"F1":"Hospital","F2":"Restaurant","F3":"Playground","F4":"Train Station","F5":"Supermarket","F6":"Aquarium"}'::jsonb),
  ('school', '{"F1":"Calculator","F2":"Whiteboard","F3":"Uniform","F4":"Lunchbox","F5":"Assembly","F6":"Report Card"}'::jsonb),
  ('sports', '{"F1":"Pickleball","F2":"Netball","F3":"Sailing","F4":"Taekwondo","F5":"Weightlifting","F6":"Water Polo"}'::jsonb),
  ('music', '{"F1":"Cello","F2":"Tambourine","F3":"Headphones","F4":"Rap","F5":"Conductor","F6":"Songwriter"}'::jsonb),
  ('jobs', '{"F1":"Baker","F2":"Police Officer","F3":"Florist","F4":"Pharmacist","F5":"Flight Attendant","F6":"Carpenter"}'::jsonb),
  ('technology', '{"F1":"Smart TV","F2":"Webcam","F3":"Microchip","F4":"Video Call","F5":"Search Engine","F6":"QR Code"}'::jsonb),
  ('nature', '{"F1":"Breeze","F2":"Pond","F3":"Jungle","F4":"Lightning","F5":"Dew","F6":"Water Lily"}'::jsonb),
  ('household', '{"F1":"Iron","F2":"Mop","F3":"Dishwasher","F4":"Mattress","F5":"Doormat","F6":"Hanger"}'::jsonb),
  ('travel', '{"F1":"Visa","F2":"Itinerary","F3":"Tourist","F4":"Jet Lag","F5":"Travel Pillow","F6":"Boarding Pass"}'::jsonb),
  ('games', '{"F1":"Monopoly","F2":"Uno","F3":"Blackjack","F4":"Snakes and Ladders","F5":"Dungeons and Dragons","F6":"Lego"}'::jsonb),
  ('fruits', '{"F1":"Mandarin","F2":"Starfruit","F3":"Rambutan","F4":"Mangosteen","F5":"Nectarine","F6":"Persimmon"}'::jsonb),
  ('landmarks', '{"F1":"Notre-Dame","F2":"Tower Bridge","F3":"Forbidden City","F4":"CN Tower","F5":"Neuschwanstein Castle","F6":"Borobudur"}'::jsonb),
  ('feelings', '{"F1":"Inspired","F2":"Overwhelmed","F3":"Cheerful","F4":"Homesick","F5":"Determined","F6":"Awkward"}'::jsonb),
  ('hobbies', '{"F1":"Journaling","F2":"Crochet","F3":"Rock Climbing","F4":"Scrapbooking","F5":"Bonsai","F6":"Piano"}'::jsonb),
  ('celebrities', '{"F1":"Stephen Curry","F2":"Emma Watson","F3":"Simu Liu","F4":"Lisa","F5":"Roger Federer","F6":"Rowan Atkinson"}'::jsonb),
  ('subjects', '{"F1":"Algebra","F2":"Coding","F3":"Nutrition","F4":"Political Science","F5":"Architecture","F6":"Film Studies"}'::jsonb),
  ('actors', '{"F1":"Emma Watson","F2":"Pedro Pascal","F3":"Florence Pugh","F4":"Donnie Yen","F5":"Awkwafina","F6":"Dev Patel"}'::jsonb),
  ('body-parts', '{"F1":"Forehead","F2":"Palm","F3":"Heel","F4":"Spine","F5":"Lips","F6":"Eyebrow"}'::jsonb),
  ('tv-shows', '{"F1":"Ted Lasso","F2":"The Bear","F3":"Bluey","F4":"The Last of Us","F5":"Community","F6":"The Good Place"}'::jsonb),
  ('songs', '{"F1":"Espresso","F2":"APT.","F3":"Birds of a Feather","F4":"Shallow","F5":"I Want It That Way","F6":"Viva La Vida"}'::jsonb),
  ('mrt-stations', '{"F1":"Caldecott","F2":"Stevens","F3":"Promenade","F4":"MacPherson","F5":"Holland Village","F6":"Beauty World"}'::jsonb),
  ('drinks', '{"F1":"Matcha","F2":"Americano","F3":"Sugarcane Juice","F4":"Barley Water","F5":"Mango Lassi","F6":"Yakult"}'::jsonb),
  ('bands', '{"F1":"Oasis","F2":"Blink-182","F3":"Radiohead","F4":"My Chemical Romance","F5":"Boyzone","F6":"The Beach Boys"}'::jsonb),
  ('singers', '{"F1":"Sabrina Carpenter","F2":"Chappell Roan","F3":"Post Malone","F4":"Sam Smith","F5":"Sia","F6":"Charli XCX"}'::jsonb),
  ('fairy-tales', '{"F1":"The Little Match Girl","F2":"The Magic Porridge Pot","F3":"The Ant and the Grasshopper","F4":"The Goose Girl","F5":"The Town Mouse and the Country Mouse","F6":"The Velveteen Rabbit"}'::jsonb),
  ('mythical-creatures', '{"F1":"Troll","F2":"Leprechaun","F3":"Satyr","F4":"Gargoyle","F5":"Wendigo","F6":"Selkie"}'::jsonb),
  ('under-the-sea', '{"F1":"Sea Cucumber","F2":"Hammerhead Shark","F3":"Blue Tang","F4":"Nautilus","F5":"Sea Anemone","F6":"Manatee"}'::jsonb),
  ('musicals', '{"F1":"Hadestown","F2":"Beetlejuice","F3":"Newsies","F4":"Dreamgirls","F5":"The Wizard of Oz","F6":"Beauty and the Beast"}'::jsonb),
  ('zoo', '{"F1":"Mandrill","F2":"Capybara","F3":"Wombat","F4":"Armadillo","F5":"Iguana","F6":"Toucan"}'::jsonb),
  ('famous-characters', '{"F1":"Deadpool","F2":"Moana","F3":"Totoro","F4":"Optimus Prime","F5":"Doraemon","F6":"Indiana Jones"}'::jsonb),
  ('no-1-hits', '{"F1":"Poker Face","F2":"Royals","F3":"Senorita","F4":"Anti-Hero","F5":"Drivers License","F6":"Good 4 U"}'::jsonb),
  ('christmas', '{"F1":"Rudolph","F2":"Eggnog","F3":"Boxing Day","F4":"Secret Santa","F5":"Christmas Eve","F6":"Snow Globe"}'::jsonb),
  ('things-flush-down', '{"F1":"Rubber Duck","F2":"Earring","F3":"Crayon","F4":"Hair Clip","F5":"Sticker","F6":"Marble"}'::jsonb),
  ('brands', '{"F1":"Spotify","F2":"TikTok","F3":"Lululemon","F4":"Dyson","F5":"Airbnb","F6":"Shopee"}'::jsonb)
) as extras(slug, board_data)
where wb.slug = extras.slug;
