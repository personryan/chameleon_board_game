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

export async function renamePlayer(roomCode, playerName) {
  const playerId = localPlayerRepository.getRememberedPlayerId(roomCode);
  if (!playerId) throw new Error('This device is not registered as a player in this room.');
  await gameRepository.renamePlayer(roomCode, playerId, playerName.trim());
}

export async function removePlayer(roomCode, playerId) {
  const requestingPlayerId = localPlayerRepository.getRememberedPlayerId(roomCode);
  if (!requestingPlayerId) throw new Error('This device is not registered as a player in this room.');
  if (!playerId) throw new Error('Choose a player to remove.');
  await gameRepository.removePlayer(roomCode, requestingPlayerId, playerId);
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

  const roundBoard = board && room.selectedBoardData
    ? { ...board, boardData: room.selectedBoardData }
    : board;

  return { room, players, currentPlayer, board: roundBoard, boards };
}

export function subscribeToRoom(roomCode, onChange) {
  return gameRepository.subscribeToRoomChanges(roomCode, onChange);
}
