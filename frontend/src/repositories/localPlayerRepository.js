import { PLAYER_KEY } from '../constants.js';

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

export function rememberPlayer(roomCode, playerId) {
  localStorage.setItem(
    PLAYER_KEY,
    JSON.stringify({ ...getPlayerIdsByRoom(), [roomCode.toUpperCase()]: playerId }),
  );
}

export function getRememberedPlayerId(roomCode) {
  return getPlayerIdsByRoom()[roomCode.toUpperCase()] ?? null;
}
