import * as gameRepository from '../repositories/gameRepository.js';
import * as localPlayerRepository from '../repositories/localPlayerRepository.js';

export async function createRoom(hostName) {
  const result = await gameRepository.createRoom(hostName.trim());
  localPlayerRepository.rememberPlayer(result.roomCode, result.playerId);
  return result.roomCode;
}

export async function joinRoom(roomCode, playerName) {
  const result = await gameRepository.joinRoom(roomCode.trim().toUpperCase(), playerName.trim());
  localPlayerRepository.rememberPlayer(result.roomCode, result.playerId);
  return result.roomCode;
}

export async function startRound(roomCode) {
  const playerId = localPlayerRepository.getRememberedPlayerId(roomCode);
  if (!playerId) throw new Error('This device is not registered as a player in this room.');
  await gameRepository.startRound(roomCode, playerId);
}

export async function revealResult(roomCode) {
  const playerId = localPlayerRepository.getRememberedPlayerId(roomCode);
  if (!playerId) throw new Error('This device is not registered as a player in this room.');
  await gameRepository.revealResult(roomCode, playerId);
}

export async function updateRoomSettings(roomCode, preferredBoardId, roundDurationSeconds) {
  const playerId = localPlayerRepository.getRememberedPlayerId(roomCode);
  if (!playerId) throw new Error('This device is not registered as a player in this room.');
  await gameRepository.updateRoomSettings(
    roomCode,
    playerId,
    preferredBoardId || null,
    Number(roundDurationSeconds),
  );
}

export async function loadRoomState(roomCode) {
  const room = await gameRepository.findRoomByCode(roomCode);
  if (!room) return { room: null, players: [], currentPlayer: null, board: null, boards: [] };

  const [players, board, boards] = await Promise.all([
    gameRepository.listPlayers(room.id),
    gameRepository.findBoard(room.selectedBoardId),
    gameRepository.listBoards(),
  ]);
  const currentPlayerId = localPlayerRepository.getRememberedPlayerId(room.roomCode);
  const currentPlayer = currentPlayerId
    ? players.find((player) => player.id === currentPlayerId) ?? null
    : null;

  return { room, players, currentPlayer, board, boards };
}

export function subscribeToRoom(roomCode, onChange) {
  return gameRepository.subscribeToRoomChanges(roomCode, onChange);
}
