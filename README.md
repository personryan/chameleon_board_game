# Chameleon Board Game MVP

A mobile-first web assistant for an in-person Chameleon-style party game. Players can create or join a room, reveal private roles, use a shared 3-minute timer, reveal the result, and start another round.

## Run locally

```bash
npm run dev
```

Then open `http://127.0.0.1:5173`.

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

This MVP is dependency-free and stores room state in browser `localStorage`, with cross-tab updates through the browser `storage` event. That keeps the prototype easy to run without Supabase credentials, but a production multi-phone game should replace the storage functions in `src/app.js` with a realtime backend such as Supabase.
