import * as gameService from '../services/gameService.js';
import { homePage, joinPage, missingConfigPage, roomPage } from '../views/pages.js';

export function createAppController(app) {
  const roomCache = new Map();
  let activeRoomCode = null;
  let unsubscribeRoom = null;
  let bootError = null;

  function extractRoomCode(value = '') {
    const match = decodeURIComponent(value).toUpperCase().match(/[A-Z0-9]{5,6}$/);
    return match?.[0] ?? null;
  }

  function getRoute() {
    const [, route = '', roomCode = ''] = window.location.pathname.split('/');
    const decodedRoute = decodeURIComponent(route);
    if (decodedRoute === 'room' && roomCode) return { name: 'room', roomCode: decodeURIComponent(roomCode).toUpperCase() };
    if (decodedRoute === 'join') {
      const searchRoomCode = new URLSearchParams(window.location.search).get('room');
      return { name: 'join', roomCode: extractRoomCode(roomCode || searchRoomCode || '') };
    }
    if (decodedRoute.toLowerCase().startsWith('join')) return { name: 'join', roomCode: extractRoomCode(decodedRoute) };
    return { name: 'home' };
  }

  function currentRoomCode() {
    const route = getRoute();
    return route.name === 'room' ? route.roomCode : null;
  }

  function showError(id, message) {
    const element = document.querySelector(`#${id}`);
    if (!element) return;
    element.textContent = message;
    element.hidden = false;
  }

  function navigate(path) {
    window.history.pushState({}, '', path);
    render();
  }

  async function refreshRoom(roomCode) {
    try {
      roomCache.set(roomCode, await gameService.loadRoomState(roomCode));
      render();
    } catch (error) {
      roomCache.set(roomCode, {
        room: null,
        players: [],
        currentPlayer: null,
        board: null,
        boards: [],
        error: error instanceof Error ? error.message : 'Could not load room.',
      });
      render();
    }
  }

  function syncSubscription(route) {
    if (route.name !== 'room') {
      if (unsubscribeRoom) unsubscribeRoom();
      unsubscribeRoom = null;
      activeRoomCode = null;
      return;
    }

    if (activeRoomCode === route.roomCode) return;
    if (unsubscribeRoom) unsubscribeRoom();
    activeRoomCode = route.roomCode;
    unsubscribeRoom = gameService.subscribeToRoom(route.roomCode, () => refreshRoom(route.roomCode));
    refreshRoom(route.roomCode);
  }

  function render() {
    if (bootError) {
      app.innerHTML = missingConfigPage(bootError);
      return;
    }

    const route = getRoute();
    syncSubscription(route);

    if (route.name === 'room') app.innerHTML = roomPage(route.roomCode, roomCache.get(route.roomCode));
    else if (route.name === 'join') app.innerHTML = joinPage(route.roomCode);
    else app.innerHTML = homePage();
  }

  async function handleSubmit(event) {
    event.preventDefault();
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    if (form.id === 'create-room-form') {
      const hostName = new FormData(form).get('hostName')?.toString() ?? '';
      if (!hostName.trim()) return showError('create-error', 'Enter your name to create a room.');

      try {
        navigate(`/room/${await gameService.createRoom(hostName)}`);
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
        navigate(`/room/${await gameService.joinRoom(roomCode, playerName)}`);
      } catch (error) {
        showError('join-error', error instanceof Error ? error.message : 'Could not join room.');
      }
    }

    if (form.id === 'room-settings-form') {
      const roomCode = currentRoomCode();
      if (!roomCode) return;

      const formData = new FormData(form);
      const preferredBoardId = formData.get('preferredBoardId')?.toString() ?? '';
      const roundDurationSeconds = formData.get('roundDurationSeconds')?.toString() ?? '180';

      try {
        await gameService.updateRoomSettings(roomCode, preferredBoardId, roundDurationSeconds);
        await refreshRoom(roomCode);
      } catch (error) {
        showError('settings-error', error instanceof Error ? error.message : 'Could not update settings.');
      }
    }
  }

  function handleInput(event) {
    if (event.target instanceof HTMLInputElement && event.target.id === 'room-code') {
      event.target.value = event.target.value.toUpperCase();
    }
  }

  async function handleClick(event) {
    const button = event.target.closest('button[data-action]');
    if (!button) return;

    const action = button.dataset.action;
    const roomCode = currentRoomCode();

    try {
      if (action === 'home') navigate('/');
      if (action === 'join-page') navigate('/join');
      if (action === 'start-round' && roomCode) await gameService.startRound(roomCode);
      if (action === 'reveal-result' && roomCode) await gameService.revealResult(roomCode);
      if ((action === 'start-round' || action === 'reveal-result') && roomCode) await refreshRoom(roomCode);
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
        await navigator.clipboard?.writeText(`${window.location.origin}/join/${roomCode}`);
        button.textContent = '✓';
        setTimeout(() => { button.textContent = '↗'; }, 1200);
      }
    } catch (error) {
      showError('room-error', error instanceof Error ? error.message : 'Something went wrong.');
    }
  }

  function start(errorMessage = null) {
    bootError = errorMessage;
    document.addEventListener('submit', handleSubmit);
    document.addEventListener('input', handleInput);
    document.addEventListener('click', handleClick);
    window.addEventListener('popstate', render);
    window.setInterval(() => {
      const roomCode = currentRoomCode();
      const room = roomCode ? roomCache.get(roomCode)?.room : null;
      if (room?.status === 'playing') render();
    }, 1_000);
    render();
  }

  return { start };
}
