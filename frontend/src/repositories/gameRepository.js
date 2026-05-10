import { getSupabaseClient } from './supabaseClient.js';

function unwrapSingleRpc(data) {
  return Array.isArray(data) ? data[0] : data;
}

function mapRoom(row) {
  if (!row) return null;
  return {
    id: row.id,
    roomCode: row.room_code,
    status: row.status,
    hostPlayerId: row.host_player_id,
    selectedBoardId: row.selected_board_id,
    preferredBoardId: row.preferred_board_id,
    selectedCoordinate: row.selected_coordinate,
    selectedWord: row.selected_word,
    chameleonPlayerId: row.chameleon_player_id,
    timerStartedAt: row.timer_started_at,
    roundDurationSeconds: row.round_duration_seconds,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapPlayer(row) {
  return {
    id: row.id,
    roomId: row.room_id,
    name: row.name,
    isHost: row.is_host,
    role: row.role,
    joinedAt: row.joined_at,
    lastSeenAt: row.last_seen_at,
  };
}

function mapBoard(row) {
  if (!row) return null;
  return {
    id: row.id,
    slug: row.slug,
    category: row.category,
    boardData: row.board_data,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function throwIfError(error) {
  if (error) throw new Error(error.message);
}

export async function createRoom(hostName) {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase.rpc('create_room', { host_name: hostName });
  throwIfError(error);
  const result = unwrapSingleRpc(data);
  return { roomId: result.room_id, roomCode: result.room_code, playerId: result.player_id };
}

export async function joinRoom(roomCode, playerName) {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase.rpc('join_room', {
    join_code: roomCode,
    player_name: playerName,
  });
  throwIfError(error);
  const result = unwrapSingleRpc(data);
  return { roomId: result.room_id, roomCode: result.room_code, playerId: result.player_id };
}

export async function startRound(roomCode, playerId) {
  const supabase = getSupabaseClient();
  const { error } = await supabase.rpc('start_round', {
    target_room_code: roomCode,
    requesting_player_id: playerId,
  });
  throwIfError(error);
}

export async function revealResult(roomCode, playerId) {
  const supabase = getSupabaseClient();
  const { error } = await supabase.rpc('reveal_result', {
    target_room_code: roomCode,
    requesting_player_id: playerId,
  });
  throwIfError(error);
}

export async function updateRoomSettings(roomCode, playerId, preferredBoardId, roundDurationSeconds) {
  const supabase = getSupabaseClient();
  const { error } = await supabase.rpc('update_room_settings', {
    target_room_code: roomCode,
    requesting_player_id: playerId,
    preferred_board_id: preferredBoardId,
    round_duration_seconds: roundDurationSeconds,
  });
  throwIfError(error);
}

export async function findRoomByCode(roomCode) {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('rooms')
    .select('*')
    .eq('room_code', roomCode.toUpperCase())
    .maybeSingle();
  throwIfError(error);
  return mapRoom(data);
}

export async function listBoards() {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('word_boards')
    .select('*')
    .eq('is_active', true)
    .order('category', { ascending: true });
  throwIfError(error);
  return data.map(mapBoard);
}

export async function listPlayers(roomId) {
  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('players')
    .select('*')
    .eq('room_id', roomId)
    .order('joined_at', { ascending: true });
  throwIfError(error);
  return data.map(mapPlayer);
}

export async function findBoard(boardId) {
  if (!boardId) return null;

  const supabase = getSupabaseClient();
  const { data, error } = await supabase
    .from('word_boards')
    .select('*')
    .eq('id', boardId)
    .maybeSingle();
  throwIfError(error);
  return mapBoard(data);
}

export function subscribeToRoomChanges(roomCode, onChange) {
  const supabase = getSupabaseClient();
  const channel = supabase
    .channel(`room:${roomCode}`)
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'rooms',
      filter: `room_code=eq.${roomCode.toUpperCase()}`,
    }, onChange)
    .on('postgres_changes', {
      event: '*',
      schema: 'public',
      table: 'players',
    }, onChange)
    .subscribe();

  return () => supabase.removeChannel(channel);
}
