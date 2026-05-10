## MVP Scope

The MVP should include only the essential features needed to play a complete round.

### Required MVP Features

1. Create a room
2. Join a room with a room code
3. Enter player name
4. Show lobby with player list
5. Host can start the game
6. Randomly assign one chameleon
7. Assign all other players as commons
8. Randomly select a word board
9. Randomly select a coordinate from the board
10. Show different screens based on role
11. Show 3-minute countdown timer
12. Allow host to reveal the result
13. Show chameleon, secret word, coordinate, and category on result screen
14. Allow host to start a new round

---

## Non-MVP Features

The following features should not be prioritised for the first version:

```txt
User accounts
Login system
Persistent profiles
Online chat
Built-in voice or video
Automated round-robin turn system
Digital voting
Score tracking
Game history
Advanced admin panel
Custom board creation
Multiple chameleons
Spectator mode
```

These can be added later after the core experience works.

---

## Suggested Tech Stack

Recommended stack:

```txt
Frontend: React or Next.js
Styling: Tailwind CSS
Backend / Realtime State: Supabase
Hosting: Vercel
Database: Supabase PostgreSQL
```

Supabase is useful for:

```txt
Rooms
Players
Game state
Realtime updates
Word board storage
```

Authentication is not required for MVP.

Players can be tracked using temporary player IDs stored in local storage.

---

## Suggested Routes

Suggested routes/pages:

```txt
/
/join
/room/[roomCode]
/game/[roomCode]
/result/[roomCode]
```

Alternative simplified route structure:

```txt
/
/room/[roomCode]
```

The room page can conditionally render lobby, game, and result views based on room status.

---

## Suggested Data Model

## Table: rooms

Stores room-level game state.

```txt
id
room_code
status
host_player_id
selected_board_id
selected_coordinate
selected_word
chameleon_player_id
timer_started_at
created_at
updated_at
```

Possible `status` values:

```txt
waiting
playing
ended
```

---

## Table: players

Stores players who joined a room.

```txt
id
room_id
name
is_host
role
joined_at
```

Possible `role` values:

```txt
common
chameleon
```

`role` can be null while the room is still waiting.

---

## Table: word_boards

Stores available game boards.

```txt
id
category
board_data
created_at
```

`board_data` can be stored as JSON.

Example:

```json
{
  "A1": "Pizza",
  "A2": "Sushi",
  "A3": "Burger",
  "A4": "Pasta",
  "A5": "Ramen",
  "A6": "Taco",
  "B1": "Curry",
  "B2": "Hotpot",
  "B3": "Laksa",
  "B4": "Noodles",
  "B5": "Steak",
  "B6": "Salad"
}
```

The full board should use rows `A` to `E` and columns `1` to `6`.

This gives 30 words per board.

---

## Initial Word Board Categories

For MVP, seed 3 to 5 simple categories.

Suggested categories:

```txt
Food
Animals
Movies
Places
School
```

Each board should contain 30 words.

---

# MVP Development Plan

## Phase 1: Project Setup

Goal:

Create the base application structure.

Tasks:

- Set up React or Next.js project
- Set up Tailwind CSS
- Create base layout
- Create routes/pages
- Set up Supabase client
- Add environment variables
- Create basic mobile-first styling system

Pages to scaffold:

```txt
/
/join
/room/[roomCode]
/game/[roomCode]
/result/[roomCode]
```

---

## Phase 2: Database Setup

Goal:

Create the required database tables.

Tasks:

- Create `rooms` table
- Create `players` table
- Create `word_boards` table
- Add basic seed word boards
- Set up Supabase policies if needed
- Confirm read/write access works for MVP

Initial boards can be hardcoded first, then moved to Supabase later if needed.

---

## Phase 3: Room Creation

Goal:

Allow a host to create a room.

Tasks:

- Create home page
- Add player name input for host
- Generate a short room code
- Create a room record
- Create the host player record
- Store local player ID in local storage
- Redirect host to lobby
- Display room code in lobby

Room code format:

```txt
4 to 6 uppercase letters/numbers
Example: X7KD2
```

---

## Phase 4: Join Room

Goal:

Allow other players to join with a room code.

Tasks:

- Create join room form
- Validate room code is provided
- Validate player name is provided
- Validate room exists
- Validate room is still in `waiting` status
- Add player to room
- Store local player ID in local storage
- Redirect player to lobby
- Show updated player list to all players

---

## Phase 5: Lobby Realtime Updates

Goal:

Keep the lobby synced across devices.

Tasks:

- Subscribe to players in the current room
- Show player list
- Show room code clearly
- Show host-only Start Game button
- Disable Start Game if not enough players
- Automatically move players to game view when room status changes to `playing`

Minimum player count:

```txt
3 players
```

Recommended:

```txt
4 or more players
```

---

## Phase 6: Start Game Logic

Goal:

Assign roles and create the round state.

Tasks:

- Fetch all players in room
- Randomly select one player as chameleon
- Randomly select one word board
- Randomly select one coordinate from `A1` to `E6`
- Get selected word from board data
- Update all player roles
- Update room with selected board, coordinate, word, chameleon player ID, and timer start time
- Change room status to `playing`

Important:

The chameleon should never see the selected word in the UI.

Even if the selected word exists in the room state, the frontend must avoid displaying it to the chameleon.

---

## Phase 7: Role-Based Game Screen

Goal:

Show each player the correct game information.

Tasks:

- Fetch current player using local player ID
- Fetch current room state
- Fetch selected board
- If player is common, show board and coordinate
- If player is chameleon, show chameleon-only screen
- Add tap-to-reveal interaction

Common view should include:

```txt
Role
Category
Board
Secret coordinate
Timer
```

Chameleon view should include:

```txt
Role
Instruction text
Timer
```

---

## Phase 8: Timer

Goal:

Show a shared 3-minute countdown.

Tasks:

- Use room `timer_started_at`
- Calculate remaining time on client
- Default round duration: 180 seconds
- Show countdown in `MM:SS`
- When timer reaches 0, show `Time's up`
- Add host-only `Reveal Result` button

Avoid relying only on local countdown state.

The timer should be derived from the stored start time so all devices stay mostly synced.

---

## Phase 9: End Round and Reveal

Goal:

Allow the host to reveal the answer.

Tasks:

- Add host-only `Reveal Result` button
- Update room status to `ended`
- Show chameleon name
- Show selected word
- Show selected coordinate
- Show selected category
- Add `Start New Round` button for host

For MVP, do not add digital voting yet.

The group can vote in person before the host reveals the result.

---

## Phase 10: Start New Round

Goal:

Allow replay without creating a new room.

Tasks:

- Keep same players in the room
- Clear previous roles
- Select a new chameleon
- Select a new board
- Select a new coordinate
- Reset timer
- Update room status back to `playing`

Optional later improvement:

```txt
Avoid selecting the same chameleon twice in a row
```

For MVP, pure random selection is acceptable.

---

# Mobile-First UX Guidelines

The app should be designed primarily for phones.

Important UX principles:

```txt
Large buttons
Clear role display
Minimal text during gameplay
Easy-to-read timer
Avoid cluttered layouts
Avoid requiring typing after the game starts
Make room code highly visible
Make role reveal private and intentional
Prevent accidental role exposure where possible
```

---

# Future Enhancements

## Digital Voting

Players vote for who they think the chameleon is.

Flow:

```txt
Timer ends
Players vote
Most voted player is revealed
Actual chameleon is revealed
Secret word is revealed
```

---

## Score Tracking

Possible scoring:

```txt
Commons win if they correctly identify the chameleon.
Chameleon wins if they avoid being caught.
Chameleon can get bonus points if they guess the secret word.
```

---

## Custom Boards

Allow users to create their own categories and words.

---

## Game Settings

Allow host to configure:

```txt
Timer duration
Number of chameleons
Whether chameleon can see category
Whether voting is digital or in person
```

---

## Better Role Privacy

Add stronger protection against accidental peeking:

```txt
Hold to reveal
Blurred role card
Auto-hide role after a few seconds
Require tap again to reveal
```

---

# MVP Success Criteria

The MVP is successful if a group of players can:

1. Open the website on their phones
2. Create a room
3. Join the room with a code
4. Start a game
5. Receive different role screens
6. Let commons see the board and coordinate
7. Let the chameleon see only their role
8. Use the 3-minute timer
9. Discuss in person
10. Reveal the chameleon and secret word
11. Start another round

The MVP should prioritise speed, clarity, and mobile usability over complex game automation.