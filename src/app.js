const ROUND_DURATION_SECONDS = 180;
const STORAGE_KEY = 'chameleon-mvp-state';
const PLAYER_KEY = 'chameleon-mvp-player-ids';
const rows = ['A', 'B', 'C', 'D', 'E'];
const columns = [1, 2, 3, 4, 5, 6];
const coordinates = rows.flatMap((row) => columns.map((column) => `${row}${column}`));
const app = document.querySelector('#app');

function makeBoard(id, category, words) {
  return {
    id,
    category,
    boardData: Object.fromEntries(coordinates.map((coordinate, index) => [coordinate, words[index]])),
  };
}

const wordBoards = [
  makeBoard('food', 'Food', [
    'Pizza', 'Sushi', 'Burger', 'Pasta', 'Ramen', 'Taco',
    'Curry', 'Hotpot', 'Laksa', 'Noodles', 'Steak', 'Salad',
    'Dumpling', 'Falafel', 'Waffle', 'Pancake', 'Burrito', 'Paella',
    'Pho', 'Kebab', 'Risotto', 'Bagel', 'Donut', 'Gelato',
    'Brownie', 'Nachos', 'Omelet', 'Kimchi', 'Lasagna', 'Croissant',
  ]),
  makeBoard('animals', 'Animals', [
    'Tiger', 'Penguin', 'Koala', 'Giraffe', 'Otter', 'Panda',
    'Dolphin', 'Eagle', 'Fox', 'Kangaroo', 'Lion', 'Moose',
    'Octopus', 'Rabbit', 'Shark', 'Turtle', 'Whale', 'Zebra',
    'Badger', 'Camel', 'Flamingo', 'Gorilla', 'Hamster', 'Iguana',
    'Jaguar', 'Lemur', 'Narwhal', 'Owl', 'Raccoon', 'Sloth',
  ]),
  makeBoard('movies', 'Movies', [
    'Titanic', 'Jaws', 'Frozen', 'Avatar', 'Rocky', 'Grease',
    'Shrek', 'Up', 'Cars', 'Coco', 'Moana', 'Dune',
    'Alien', 'Psycho', 'Casablanca', 'Matilda', 'Twister', 'Godzilla',
    'Mulan', 'Aladdin', 'WALL-E', 'Ratatouille', 'Inception', 'Interstellar',
    'Batman', 'Superman', 'Spider-Man', 'Gladiator', 'Minions', 'Paddington',
  ]),
  makeBoard('places', 'Places', [
    'Paris', 'Tokyo', 'London', 'Cairo', 'Sydney', 'Rome',
    'Berlin', 'Dubai', 'Toronto', 'Boston', 'Chicago', 'Seattle',
    'Beach', 'Museum', 'Airport', 'Castle', 'Desert', 'Forest',
    'Island', 'Market', 'Mountain', 'Park', 'School', 'Stadium',
    'Theater', 'Village', 'Zoo', 'Harbor', 'Library', 'Cafe',
  ]),
  makeBoard('school', 'School', [
    'Pencil', 'Notebook', 'Backpack', 'Teacher', 'Homework', 'Quiz',
    'Science', 'Math', 'History', 'Art', 'Music', 'Recess',
    'Cafeteria', 'Locker', 'Desk', 'Ruler', 'Eraser', 'Marker',
    'Project', 'Library', 'Gym', 'Bus', 'Bell', 'Grade',
    'Essay', 'Exam', 'Principal', 'Classroom', 'Schedule', 'Textbook',
  ]),
];

function createId(prefix = 'id') {
  if (globalThis.crypto?.randomUUID) return `${prefix}_${globalThis.crypto.randomUUID()}`;
  return `${prefix}_${Math.random().toString(36).slice(2)}_${Date.now().toString(36)}`;
}

function loadState() {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return { rooms: {}, players: {} };

  try {
    return JSON.parse(raw);
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    return { rooms: {}, players: {} };
  }
}

function saveState(state) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  render();
}

function updateState(updater) {
  const nextState = updater(loadState());
  saveState(nextState);
  return nextState;
}

function getPlayerIdsByRoom() {
  const raw = localStorage.getItem(PLAYER_KEY);
  if (!raw) return {};

  try {
    return JSON.parse(raw);
  } catch {
    localStorage.removeItem(PLAYER_KEY);
    return {};
  }
}

function rememberPlayer(roomCode, playerId) {
  localStorage.setItem(
    PLAYER_KEY,
    JSON.stringify({ ...getPlayerIdsByRoom(), [roomCode.toUpperCase()]: playerId }),
  );
}

function getRememberedPlayerId(roomCode) {
  return getPlayerIdsByRoom()[roomCode.toUpperCase()] ?? null;
}

function getRoomPlayers(state, roomCode) {
  return Object.values(state.players)
    .filter((player) => player.roomCode === roomCode.toUpperCase())
    .sort((a, b) => a.joinedAt.localeCompare(b.joinedAt));
}

function generateRoomCode(existingCodes) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';

  do {
    code = Array.from({ length: 5 }, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join('');
  } while (existingCodes.includes(code));

  return code;
}

function createRoom(hostName) {
  const now = new Date().toISOString();
  const playerId = createId('player');
  let roomCode = '';

  updateState((current) => {
    roomCode = generateRoomCode(Object.keys(current.rooms));
    return {
      rooms: {
        ...current.rooms,
        [roomCode]: {
          id: createId('room'),
          roomCode,
          status: 'waiting',
          hostPlayerId: playerId,
          selectedBoardId: null,
          selectedCoordinate: null,
          selectedWord: null,
          chameleonPlayerId: null,
          timerStartedAt: null,
          createdAt: now,
          updatedAt: now,
        },
      },
      players: {
        ...current.players,
        [playerId]: {
          id: playerId,
          roomCode,
          name: hostName.trim(),
          isHost: true,
          role: null,
          joinedAt: now,
        },
      },
    };
  });

  rememberPlayer(roomCode, playerId);
  return roomCode;
}

function joinRoom(roomCode, playerName) {
  const normalizedCode = roomCode.trim().toUpperCase();
  const now = new Date().toISOString();
  const playerId = createId('player');

  updateState((current) => {
    const room = current.rooms[normalizedCode];
    if (!room) throw new Error('Room not found. Check the code and try again.');
    if (room.status !== 'waiting') throw new Error('This room already started. Create a new room to play.');

    return {
      ...current,
      players: {
        ...current.players,
        [playerId]: {
          id: playerId,
          roomCode: normalizedCode,
          name: playerName.trim(),
          isHost: false,
          role: null,
          joinedAt: now,
        },
      },
    };
  });

  rememberPlayer(normalizedCode, playerId);
  return normalizedCode;
}

function pickRandom(items) {
  return items[Math.floor(Math.random() * items.length)];
}

function startRound(roomCode) {
  const normalizedCode = roomCode.toUpperCase();

  updateState((current) => {
    const room = current.rooms[normalizedCode];
    if (!room) throw new Error('Room not found.');

    const players = getRoomPlayers(current, normalizedCode);
    if (players.length < 3) throw new Error('At least 3 players are required to start.');

    const chameleon = pickRandom(players);
    const board = pickRandom(wordBoards);
    const coordinate = pickRandom(coordinates);
    const now = new Date().toISOString();
    const updatedPlayers = Object.fromEntries(players.map((player) => [
      player.id,
      { ...player, role: player.id === chameleon.id ? 'chameleon' : 'common' },
    ]));

    return {
      rooms: {
        ...current.rooms,
        [normalizedCode]: {
          ...room,
          status: 'playing',
          selectedBoardId: board.id,
          selectedCoordinate: coordinate,
          selectedWord: board.boardData[coordinate],
          chameleonPlayerId: chameleon.id,
          timerStartedAt: now,
          updatedAt: now,
        },
      },
      players: { ...current.players, ...updatedPlayers },
    };
  });
}

function revealResult(roomCode) {
  const normalizedCode = roomCode.toUpperCase();
  updateState((current) => {
    const room = current.rooms[normalizedCode];
    if (!room) throw new Error('Room not found.');
    return {
      ...current,
      rooms: {
        ...current.rooms,
        [normalizedCode]: { ...room, status: 'ended', updatedAt: new Date().toISOString() },
      },
    };
  });
}

function navigate(path) {
  window.history.pushState({}, '', path);
  render();
}

function escapeHtml(value = '') {
  return String(value).replace(/[&<>"]/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[char]));
}

function page(content, extraClass = '') {
  return `<main class="page ${extraClass}">${content}</main>`;
}

function roomHeader(room, currentPlayer) {
  return `
    <header class="roomHeader">
      <button class="linkButton" data-action="home" type="button">Home</button>
      <div class="codeBlock"><span>Room code</span><strong>${room.roomCode}</strong></div>
      <button class="iconButton" data-action="copy" type="button" aria-label="Copy invite">↗</button>
      ${currentPlayer ? `<p class="youLine">Playing as <strong>${escapeHtml(currentPlayer.name)}</strong>${currentPlayer.isHost ? ' · Host' : ''}</p>` : ''}
    </header>`;
}

function homePage() {
  return page(`
    <div class="badge">Mobile party game MVP</div>
    <h1>Chameleon</h1>
    <p class="lede">Create a room, invite friends, reveal private roles, and find the player who does not know the secret word.</p>
    <form class="card form" id="create-room-form">
      <label for="host-name">Your name</label>
      <input id="host-name" name="hostName" placeholder="Host name" autocomplete="name" />
      <p class="error" id="create-error" hidden></p>
      <button class="primary" type="submit">Create room</button>
    </form>
    <button class="secondary" data-action="join-page" type="button">Join an existing room</button>
  `, 'hero');
}

function joinPage() {
  return page(`
    <button class="linkButton" data-action="home" type="button">← Back</button>
    <h1>Join room</h1>
    <p class="lede">Ask the host for the room code, then enter your display name.</p>
    <form class="card form" id="join-room-form">
      <label for="room-code">Room code</label>
      <input id="room-code" name="roomCode" placeholder="X7KD2" maxlength="6" autocapitalize="characters" />
      <label for="player-name">Your name</label>
      <input id="player-name" name="playerName" placeholder="Player name" autocomplete="name" />
      <p class="error" id="join-error" hidden></p>
      <button class="primary" type="submit">Join lobby</button>
    </form>
  `);
}

function lobby(room, players, currentPlayer) {
  const canStart = currentPlayer?.isHost && players.length >= 3;
  return page(`
    ${roomHeader(room, currentPlayer)}
    <section class="card lobbyCard">
      <div class="sectionTitle"><span aria-hidden="true">👥</span><h2>Lobby</h2></div>
      <p>${players.length < 3 ? 'Waiting for at least 3 players.' : 'Ready to start when the host is ready.'}</p>
      <ul class="playerList">
        ${players.map((player) => `<li><span>${escapeHtml(player.name)}</span>${player.isHost ? '<span aria-label="Host">👑</span>' : ''}</li>`).join('')}
      </ul>
    </section>
    ${currentPlayer?.isHost
      ? `<button class="primary" data-action="start-round" type="button" ${canStart ? '' : 'disabled'}>${players.length < 3 ? `Need ${3 - players.length} more` : 'Start game'}</button>`
      : '<p class="helper">Waiting for the host to start the game.</p>'}
    <p class="error" id="room-error" hidden></p>
  `);
}

function timer(room) {
  const startedAt = room.timerStartedAt ? new Date(room.timerStartedAt).getTime() : Date.now();
  const elapsedSeconds = Math.floor((Date.now() - startedAt) / 1_000);
  const remainingSeconds = Math.max(0, ROUND_DURATION_SECONDS - elapsedSeconds);
  const minutes = Math.floor(remainingSeconds / 60).toString().padStart(2, '0');
  const seconds = (remainingSeconds % 60).toString().padStart(2, '0');
  return `
    <section class="timer ${remainingSeconds === 0 ? 'timerDone' : ''}" aria-live="polite">
      <span aria-hidden="true">⏳</span>
      <div><p>${remainingSeconds === 0 ? "Time's up" : `${minutes}:${seconds}`}</p><span>Discuss. Describe. Deduce.</span></div>
    </section>`;
}

function boardGrid(room) {
  const board = wordBoards.find((item) => item.id === room.selectedBoardId);
  if (!board) return '';
  return `
    <section class="boardWrap">
      <div class="boardGrid">
        ${coordinates.map((coordinate) => `
          <div class="cell ${coordinate === room.selectedCoordinate ? 'selectedCell' : ''}">
            <span>${coordinate}</span><strong>${board.boardData[coordinate]}</strong>
          </div>`).join('')}
      </div>
    </section>`;
}

function game(room, currentPlayer) {
  const board = wordBoards.find((item) => item.id === room.selectedBoardId);
  const roleContent = currentPlayer.role === 'chameleon'
    ? `<div class="roleInner chameleonRole"><p class="eyebrow">Your role</p><h1>You are the Chameleon.</h1><p>Try to blend in. Listen carefully. Do not reveal yourself.</p></div>`
    : `<div class="roleInner"><p class="eyebrow">Your role</p><h1>You are Common.</h1><p><strong>Category:</strong> ${board?.category ?? ''}</p><p><strong>Secret coordinate:</strong> ${room.selectedCoordinate}</p></div>`;

  return page(`
    ${roomHeader(room, currentPlayer)}
    ${timer(room)}
    <section class="card roleCard" data-revealed="false">
      <button class="revealButton" data-action="reveal-role" type="button">👁 Tap to reveal your role</button>
      <div class="roleContent" hidden>${roleContent}<button class="secondary compact" data-action="hide-role" type="button">🙈 Hide role</button></div>
    </section>
    ${currentPlayer.role === 'common' ? boardGrid(room) : ''}
    ${currentPlayer.isHost ? '<button class="secondary" data-action="reveal-result" type="button">Reveal result</button>' : ''}
    <p class="error" id="room-error" hidden></p>
  `, 'gamePage');
}

function result(room, players, currentPlayer) {
  const board = wordBoards.find((item) => item.id === room.selectedBoardId);
  const chameleon = players.find((player) => player.id === room.chameleonPlayerId);
  return page(`
    ${roomHeader(room, currentPlayer)}
    <section class="card resultCard">
      <p class="eyebrow">Round result</p>
      <h1>${escapeHtml(chameleon?.name ?? 'Unknown')} was the Chameleon</h1>
      <dl class="resultList">
        <div><dt>Category</dt><dd>${board?.category ?? ''}</dd></div>
        <div><dt>Coordinate</dt><dd>${room.selectedCoordinate ?? ''}</dd></div>
        <div><dt>Secret word</dt><dd>${room.selectedWord ?? ''}</dd></div>
      </dl>
    </section>
    ${currentPlayer?.isHost
      ? '<button class="primary" data-action="start-round" type="button">↻ Start new round</button>'
      : '<p class="helper">Waiting for the host to start another round.</p>'}
    <p class="error" id="room-error" hidden></p>
  `);
}

function roomPage(roomCode) {
  const state = loadState();
  const room = state.rooms[roomCode];
  const players = getRoomPlayers(state, roomCode);
  const currentPlayerId = getRememberedPlayerId(roomCode);
  const currentPlayer = currentPlayerId ? state.players[currentPlayerId] ?? null : null;

  if (!room) {
    return page(`
      <button class="linkButton" data-action="home" type="button">← Home</button>
      <section class="card emptyState"><h1>Room not found</h1><p>Check the room code or create a new room.</p><button class="primary" data-action="join-page" type="button">Join room</button></section>
    `);
  }

  if (!currentPlayer) {
    return page(`
      ${roomHeader(room, null)}
      <section class="card emptyState"><h1>Join this room</h1><p>This device is not registered as a player in ${room.roomCode}.</p><button class="primary" data-action="join-page" type="button">Enter name to join</button></section>
    `);
  }

  if (room.status === 'waiting') return lobby(room, players, currentPlayer);
  if (room.status === 'playing') return game(room, currentPlayer);
  return result(room, players, currentPlayer);
}

function getRoute() {
  const [, route, roomCode] = window.location.pathname.split('/');
  if (route === 'room' && roomCode) return { name: 'room', roomCode: roomCode.toUpperCase() };
  if (route === 'join') return { name: 'join' };
  return { name: 'home' };
}

function showError(id, message) {
  const element = document.querySelector(`#${id}`);
  if (!element) return;
  element.textContent = message;
  element.hidden = false;
}

function render() {
  const route = getRoute();
  if (route.name === 'room') app.innerHTML = roomPage(route.roomCode);
  else if (route.name === 'join') app.innerHTML = joinPage();
  else app.innerHTML = homePage();
}

function currentRoomCode() {
  const route = getRoute();
  return route.name === 'room' ? route.roomCode : null;
}

document.addEventListener('submit', (event) => {
  event.preventDefault();
  const form = event.target;
  if (!(form instanceof HTMLFormElement)) return;

  if (form.id === 'create-room-form') {
    const hostName = new FormData(form).get('hostName')?.toString() ?? '';
    if (!hostName.trim()) return showError('create-error', 'Enter your name to create a room.');
    try {
      navigate(`/room/${createRoom(hostName)}`);
    } catch (error) {
      showError('create-error', error instanceof Error ? error.message : 'Could not create room.');
    }
  }

  if (form.id === 'join-room-form') {
    const formData = new FormData(form);
    const roomCode = formData.get('roomCode')?.toString() ?? '';
    const playerName = formData.get('playerName')?.toString() ?? '';
    if (!roomCode.trim() || !playerName.trim()) return showError('join-error', 'Enter both a room code and your name.');
    try {
      navigate(`/room/${joinRoom(roomCode, playerName)}`);
    } catch (error) {
      showError('join-error', error instanceof Error ? error.message : 'Could not join room.');
    }
  }
});

document.addEventListener('input', (event) => {
  if (event.target instanceof HTMLInputElement && event.target.id === 'room-code') {
    event.target.value = event.target.value.toUpperCase();
  }
});

document.addEventListener('click', async (event) => {
  const button = event.target.closest('button[data-action]');
  if (!button) return;

  const action = button.dataset.action;
  const roomCode = currentRoomCode();

  try {
    if (action === 'home') navigate('/');
    if (action === 'join-page') navigate('/join');
    if (action === 'start-round' && roomCode) startRound(roomCode);
    if (action === 'reveal-result' && roomCode) revealResult(roomCode);
    if (action === 'reveal-role') {
      button.hidden = true;
      button.parentElement.querySelector('.roleContent').hidden = false;
    }
    if (action === 'hide-role') {
      const card = button.closest('.roleCard');
      card.querySelector('.roleContent').hidden = true;
      card.querySelector('.revealButton').hidden = false;
    }
    if (action === 'copy' && roomCode) {
      await navigator.clipboard?.writeText(`${window.location.origin}/join — Room code: ${roomCode}`);
      button.textContent = '✓';
      setTimeout(() => { button.textContent = '↗'; }, 1200);
    }
  } catch (error) {
    showError('room-error', error instanceof Error ? error.message : 'Something went wrong.');
  }
});

window.addEventListener('popstate', render);
window.addEventListener('storage', render);
window.setInterval(() => {
  if (loadState().rooms[currentRoomCode()]?.status === 'playing') render();
}, 1_000);

render();
