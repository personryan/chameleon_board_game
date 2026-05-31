import { coordinates, ROUND_DURATION_SECONDS } from '../constants.js';
import { escapeHtml, page } from './html.js';

function inviteUrl(roomCode) {
  const origin = typeof window === 'undefined' ? '' : window.location.origin;
  return `${origin}/join/${encodeURIComponent(roomCode)}`;
}

function roomHeader(room, currentPlayer) {
  const roomCode = room.roomCode;
  const url = inviteUrl(roomCode);
  return `
    <header class="roomHeader">
      <button class="linkButton" data-action="home" type="button">Home</button>
      <div class="codeBlock">
        <span>Invite link</span>
        <a class="inviteLink" href="${escapeHtml(url)}">${escapeHtml(url)}</a>
        <strong>${escapeHtml(roomCode)}</strong>
      </div>
      <button class="iconButton" data-action="copy" type="button" aria-label="Copy invite">↗</button>
      ${currentPlayer ? `<p class="youLine">Playing as <strong>${escapeHtml(currentPlayer.name)}</strong>${currentPlayer.isHost ? ' · Host' : ''}</p>` : ''}
    </header>`;
}

function settingsPanel(room, boards) {
  const timerOptions = [
    { label: '1 min', value: 60 },
    { label: '2 min', value: 120 },
    { label: '3 min', value: 180 },
    { label: '5 min', value: 300 },
    { label: '10 min', value: 600 },
  ];

  return `
    <form class="card form settingsForm" id="room-settings-form">
      <div class="sectionTitle"><span aria-hidden="true">⚙</span><h2>Round settings</h2></div>
      <label for="preferred-board-id">Theme</label>
      <select id="preferred-board-id" name="preferredBoardId">
        <option value="" ${room.preferredBoardId ? '' : 'selected'}>Random theme</option>
        ${boards.map((board) => `<option value="${board.id}" ${room.preferredBoardId === board.id ? 'selected' : ''}>${escapeHtml(board.category)}</option>`).join('')}
      </select>
      <label for="round-duration-seconds">Timer</label>
      <select id="round-duration-seconds" name="roundDurationSeconds">
        ${timerOptions.map((option) => `<option value="${option.value}" ${Number(room.roundDurationSeconds) === option.value ? 'selected' : ''}>${option.label}</option>`).join('')}
      </select>
      <p class="error" id="settings-error" hidden></p>
      <button class="secondary compact" type="submit">Save settings</button>
      <p class="settingsHint">Changes save automatically.</p>
    </form>
  `;
}

function removalPanel(players, currentPlayer) {
  const removablePlayers = players.filter((player) => !player.isHost);
  if (!currentPlayer?.isHost || removablePlayers.length === 0) return '';

  return `
    <form class="card form" id="remove-player-form">
      <label for="remove-player-id">Remove player</label>
      <div class="inlineForm">
        <select id="remove-player-id" name="playerId">
          ${removablePlayers.map((player) => `<option value="${escapeHtml(player.id)}">${escapeHtml(player.name)}</option>`).join('')}
        </select>
        <button class="danger compact" type="submit">Remove</button>
      </div>
      <p class="error" id="remove-error" hidden></p>
    </form>`;
}

export function homePage() {
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

export function joinPage(roomCode = '') {
  return page(`
    <button class="linkButton" data-action="home" type="button">← Back</button>
    <h1>Join room</h1>
    <p class="lede">Ask the host for the room code, then enter your display name.</p>
    <form class="card form" id="join-room-form">
      <label for="room-code">Room code</label>
      <input id="room-code" name="roomCode" placeholder="X7KD2" value="${escapeHtml(roomCode)}" maxlength="6" autocapitalize="characters" />
      <label for="player-name">Your name</label>
      <input id="player-name" name="playerName" placeholder="Player name" autocomplete="name" />
      <p class="error" id="join-error" hidden></p>
      <button class="primary" type="submit">Join lobby</button>
    </form>
  `);
}

export function loadingPage() {
  return page('<section class="card emptyState"><h1>Loading room</h1><p>Syncing game state...</p></section>');
}

export function missingConfigPage(message) {
  return page(`
    <section class="card emptyState">
      <h1>Supabase setup needed</h1>
      <p>${escapeHtml(message)}</p>
    </section>
  `);
}

function lobby(room, players, currentPlayer, boards) {
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
    <form class="card form renameForm" id="rename-player-form">
      <label for="player-name">Change your name</label>
      <div class="inlineForm">
        <input id="player-name" name="playerName" value="${escapeHtml(currentPlayer.name)}" maxlength="40" autocomplete="name" />
        <button class="secondary compact" type="submit">Save</button>
      </div>
      <p class="error" id="rename-error" hidden></p>
    </form>
    ${removalPanel(players, currentPlayer)}
    ${currentPlayer?.isHost ? settingsPanel(room, boards) : ''}
    ${currentPlayer?.isHost
      ? `<button class="primary" data-action="start-round" type="button" ${canStart ? '' : 'disabled'}>${players.length < 3 ? `Need ${3 - players.length} more` : 'Start game'}</button>`
      : '<p class="helper">Waiting for the host to start the game.</p>'}
    <p class="error" id="room-error" hidden></p>
  `);
}

function timer(room) {
  const duration = room.roundDurationSeconds ?? ROUND_DURATION_SECONDS;
  const startedAt = room.timerStartedAt ? new Date(room.timerStartedAt).getTime() : Date.now();
  const elapsedSeconds = Math.floor((Date.now() - startedAt) / 1_000);
  const remainingSeconds = Math.max(0, duration - elapsedSeconds);
  const minutes = Math.floor(remainingSeconds / 60).toString().padStart(2, '0');
  const seconds = (remainingSeconds % 60).toString().padStart(2, '0');
  const endsAt = startedAt + duration * 1_000;
  return `
    <section class="timer ${remainingSeconds === 0 ? 'timerDone' : ''}" data-ends-at="${endsAt}" aria-live="polite">
      <span aria-hidden="true">⏳</span>
      <div><p data-timer-value>${remainingSeconds === 0 ? "Time's up" : `${minutes}:${seconds}`}</p><span>Discuss. Describe. Deduce.</span></div>
    </section>`;
}

function boardGrid(room, board) {
  if (!board) return '';
  return `
    <section class="boardWrap">
      <div class="boardGrid">
        ${coordinates.map((coordinate) => `
          <div class="cell ${coordinate === room.selectedCoordinate ? 'selectedCell' : ''}">
            <span>${coordinate}</span><strong>${escapeHtml(board.boardData[coordinate])}</strong>
          </div>`).join('')}
      </div>
    </section>`;
}

function game(room, players, currentPlayer, board) {
  const roleContent = currentPlayer.role === 'chameleon'
    ? `<div class="roleInner chameleonRole"><p class="eyebrow">Your role</p><h1>You are the Chameleon.</h1><p>Try to blend in. Listen carefully. Do not reveal yourself.</p></div>`
    : `<div class="roleInner"><p class="eyebrow">Your role</p><h1>You are Common.</h1><p><strong>Category:</strong> ${escapeHtml(board?.category ?? '')}</p><p><strong>Secret coordinate:</strong> ${escapeHtml(room.selectedCoordinate ?? '')}</p></div>`;

  return page(`
    ${roomHeader(room, currentPlayer)}
    ${timer(room)}
    <section class="card roleCard" data-round-started-at="${escapeHtml(room.timerStartedAt ?? '')}">
      <button class="revealButton" data-action="reveal-role" type="button">👁 Tap to reveal your role</button>
      <div class="roleContent" hidden>${roleContent}<button class="secondary compact" data-action="hide-role" type="button">🙈 Hide role</button></div>
    </section>
    ${currentPlayer.role === 'common' ? boardGrid(room, board) : ''}
    ${currentPlayer.isHost ? '<button class="secondary" data-action="reveal-result" type="button">Reveal result</button>' : ''}
    ${removalPanel(players, currentPlayer)}
    <p class="error" id="room-error" hidden></p>
  `, 'gamePage');
}

function result(room, players, currentPlayer, chameleon, board, boards) {
  return page(`
    ${roomHeader(room, currentPlayer)}
    <section class="card resultCard">
      <p class="eyebrow">Round result</p>
      <h1>${escapeHtml(chameleon?.name ?? 'Unknown')} was the Chameleon</h1>
      <dl class="resultList">
        <div><dt>Category</dt><dd>${escapeHtml(board?.category ?? '')}</dd></div>
        <div><dt>Coordinate</dt><dd>${escapeHtml(room.selectedCoordinate ?? '')}</dd></div>
        <div><dt>Secret word</dt><dd>${escapeHtml(room.selectedWord ?? '')}</dd></div>
      </dl>
    </section>
    ${removalPanel(players, currentPlayer)}
    ${currentPlayer?.isHost ? settingsPanel(room, boards) : ''}
    ${currentPlayer?.isHost
      ? '<button class="primary" data-action="start-round" type="button">↻ Start new round</button>'
      : '<p class="helper">Waiting for the host to start another round.</p>'}
    <p class="error" id="room-error" hidden></p>
  `);
}

export function roomPage(roomCode, roomState) {
  if (!roomState) return loadingPage();

  const { room, players, currentPlayer, chameleon, board, boards } = roomState;

  if (!room) {
    return page(`
      <button class="linkButton" data-action="home" type="button">← Home</button>
      <section class="card emptyState"><h1>Room not found</h1><p>Check the room code or create a new room.</p><button class="primary" data-action="join-page" type="button">Join room</button></section>
    `);
  }

  if (!currentPlayer) {
    return page(`
      ${roomHeader(room, null)}
      <section class="card emptyState"><h1>Join this room</h1><p>This device is not registered as a player in ${escapeHtml(room.roomCode ?? roomCode)}.</p><button class="primary" data-action="join-page" data-room-code="${escapeHtml(room.roomCode ?? roomCode)}" type="button">Enter name to join</button></section>
    `);
  }

  if (room.status === 'waiting') return lobby(room, players, currentPlayer, boards);
  if (room.status === 'playing') return game(room, players, currentPlayer, board);
  return result(room, players, currentPlayer, chameleon, board, boards);
}
