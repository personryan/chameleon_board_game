export const ROUND_DURATION_SECONDS = 180;
export const PLAYER_KEY = 'chameleon-mvp-player-ids';
export const rows = ['A', 'B', 'C', 'D', 'E'];
export const columns = [1, 2, 3, 4, 5, 6];
export const coordinates = rows.flatMap((row) => columns.map((column) => `${row}${column}`));
