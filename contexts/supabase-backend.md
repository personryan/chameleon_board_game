# Supabase Backend Notes

The MVP backend lives in `backend/supabase/migrations/202605100001_initial_game_backend.sql`.

## Tables

- `word_boards`: available board categories and 30-cell board JSON.
- `rooms`: room status and current round state.
- `players`: temporary player rows for each room.

The frontend should continue storing only the current `player_id` per room in local storage. Supabase stores the shared room/player state.

## RPCs

Use these functions from the client instead of manually inserting/updating multiple rows:

```js
await supabase.rpc('create_room', { host_name: hostName });
await supabase.rpc('join_room', { join_code: roomCode, player_name: playerName });
await supabase.rpc('start_round', { target_room_code: roomCode, requesting_player_id: playerId });
await supabase.rpc('reveal_result', { target_room_code: roomCode, requesting_player_id: playerId });
```

`create_room` and `join_room` both return:

```txt
room_id
room_code
player_id
```

Store `player_id` in local storage keyed by `room_code`.

## Frontend Layers

The Supabase integration is split across the frontend:

- `frontend/src/repositories`: direct Supabase calls and local player ID storage.
- `frontend/src/services`: game workflows such as creating rooms and starting rounds.
- `frontend/src/controllers`: DOM events, routing, and realtime refresh.
- `frontend/src/views`: HTML rendering.

## Realtime

Subscribe to both `rooms` and `players` for the current room:

```js
const channel = supabase
  .channel(`room:${roomCode}`)
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'rooms',
    filter: `room_code=eq.${roomCode}`,
  }, refreshRoom)
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'players',
  }, refreshPlayers)
  .subscribe();
```

Supabase realtime filters cannot filter `players` by joined room code directly, so `refreshPlayers` should re-fetch the players for the loaded `room_id`.

## MVP Security Note

This is intentionally permissive for a no-login MVP. It uses anonymous access and treats the locally stored `player_id` as the temporary player identity. That is enough for friendly in-person testing, but it is not cheat-proof: a curious player can inspect network responses. Before a public launch, move secret reveal logic behind stricter RPC/view boundaries or add Supabase Auth.
