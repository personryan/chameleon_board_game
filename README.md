# Chameleon Board Game MVP

A mobile-first web assistant for an in-person Chameleon-style party game. Players can create or join a room, reveal private roles, use a shared 3-minute timer, reveal the result, and start another round.

## Run locally

```bash
npm run dev
```

Then open `http://127.0.0.1:5173`.

The runnable web app lives in `frontend/`. You can also run it directly:

```bash
cd frontend
npm run dev
```

The frontend is a Vite app. Put browser-safe Supabase credentials in `frontend/.env`.

## Supabase backend

The backend schema, realtime setup, RPCs, and seed boards are in `backend/supabase/migrations/202605100001_initial_game_backend.sql`.

To apply it to a Supabase project:

```bash
cd backend
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Set frontend credentials from `frontend/.env.example`:

```bash
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

More wiring notes are in `contexts/supabase-backend.md`.

## Project structure

```txt
frontend/
  src/config        environment loading
  src/repositories  Supabase and local storage data access
  src/services      game workflow logic
  src/controllers   DOM events, routing, realtime refresh
  src/views         HTML rendering
backend/
  supabase/         Supabase config and migrations
```

## MVP features

- Create a room with a short uppercase room code.
- Join a waiting room with a player name.
- Store the current device's player ID in local storage.
- Show a lobby with the room code, player list, and host-only start button.
- Require at least 3 players before the host can start.
- Randomly select one chameleon, one word board, and one coordinate.
- Show private tap-to-reveal role cards.
- Show commons the category, coordinate, and board while hiding all secret board details from the chameleon.
- Show a timer derived from the stored round start timestamp.
- Let the host reveal the chameleon, category, coordinate, and secret word.
- Let the host start a new round with the same players.

## Current storage model

Shared game state now lives in Supabase. The frontend only stores the current device's temporary `player_id` per room in `localStorage`.
