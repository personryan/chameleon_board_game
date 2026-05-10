# Chameleon Game Website Context and MVP Plan

## Project Overview

This project is a mobile-first web version of a Chameleon-style party game.

The website is intended to be used mainly in person. Players gather physically and use their phones to receive their role, view the game board, and follow the timer. The app should not fully replace the in-person experience. It should act as a lightweight game assistant that handles room creation, player joining, role assignment, word selection, and the timer.

The game should be simple, fast to access, and easy to play on mobile devices.

---

## Game Concept

There are two possible roles:

### Common

Commons know the secret word for the round.

All commons see the same board. They are given a secret coordinate, such as `A5`, which points to the secret word on the board.

Example:

```txt
Coordinate: A5
Secret Word: Ramen
```

### Chameleon

The chameleon does not know the secret word.

The chameleon must blend in by listening to the other players and giving vague but believable clues.

For MVP, the chameleon should not see the board or the secret coordinate.

---

## Game Flow

### 1. Create Room

A host creates a room.

The app generates a short room code.

Example:

```txt
Room Code: X7KD2
```

Other players join the room using this code.

---

### 2. Join Room

Each player enters:

```txt
Room code
Player name
```

No login or user account is required.

Each browser/device should store the player ID in local storage so the app can identify the current player after page refreshes.

---

### 3. Lobby

The lobby shows:

```txt
Room code
Player list
Waiting message
Start Game button for host only
```

The host can start the game once enough players have joined.

Minimum recommended player count:

```txt
3 players
```

Recommended player count:

```txt
4 or more players
```

---

### 4. Start Game

When the host starts the game, the app should:

1. Randomly select one player as the chameleon.
2. Assign all other players as commons.
3. Randomly select a word board.
4. Randomly select a coordinate from `A1` to `E6`.
5. Get the selected word from the board data.
6. Store the round state.
7. Set the room status to `playing`.
8. Set `timer_started_at`.

---

### 5. Role Reveal

Each player should privately view their role.

Recommended UX:

```txt
Tap to reveal role
```

Optional stronger privacy UX:

```txt
Tap and hold to reveal role
Auto-hide role after a few seconds
Blur card before revealing
```

For MVP, a simple reveal button is acceptable.

---

## Player Views During Game

### Common Player View

Commons should see:

```txt
You are Common.
Category: Food
Secret Coordinate: A5
Board displayed below.
```

Example board:

```txt
Category: Food

A1 Pizza      A2 Sushi      A3 Burger
A4 Pasta      A5 Ramen      A6 Taco

B1 Curry      B2 Hotpot     B3 Laksa
...

Secret Coordinate: A5
```

The app can visually highlight the selected coordinate or show it clearly above the board.

The secret word itself does not need to be separately displayed if the coordinate is clear, but highlighting the coordinate is acceptable.

---

### Chameleon Player View

The chameleon should see:

```txt
You are the Chameleon.

Try to blend in.
Listen carefully.
Do not reveal yourself.
```

For MVP, the chameleon should not see:

```txt
The board
The category
The coordinate
The secret word
```

This can be changed later as a game setting.

---

## Timer

After the game starts, a 3-minute timer should begin.

The timer should be visible to all players.

Example:

```txt
03:00
Discuss. Describe. Deduce.
```

Timer requirements:

- Default duration: 180 seconds
- Timer should be based on `timer_started_at`
- Timer should be calculated from stored round state, not only local component state
- If the page refreshes, the timer should still show the correct remaining time
- When the timer reaches 0, show a clear `Time's up` state

The app does not need to enforce turn-taking.

Players will handle discussions, clues, accusations, and voting in person.

---

## In-Person Gameplay Assumption

This app supports in-person gameplay.

The following actions should not be fully controlled by the app in MVP:

```txt
Taking turns
Giving clues
Discussing accusations
Voting for the chameleon
Arguing or defending
Final group decision-making
```

The app should stay lightweight and avoid making the game feel too rigid.

---