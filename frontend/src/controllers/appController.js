import * as gameService from '../services/gameService.js';
import { homePage, joinPage, missingConfigPage, roomPage } from '../views/pages.js';

export function createAppController(app) {
  const roomCache = new Map();
  const roomStateSignatures = new Map();
  let activeRoomCode = null;
  let unsubscribeRoom = null;
  let bootError = null;
  let isPollingRoom = false;

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

  function roomStateSignature(roomState) {
    return JSON.stringify(roomState);
  }

  async function refreshRoom(roomCode, { renderIfUnchanged = true, silent = false } = {}) {
    try {
      const roomState = await gameService.loadRoomState(roomCode);
      const signature = roomStateSignature(roomState);
      const hasChanged = roomStateSignatures.get(roomCode) !== signature;
      roomCache.set(roomCode, roomState);
      roomStateSignatures.set(roomCode, signature);
      if (!hasChanged && !renderIfUnchanged) return;
      render();
    } catch (error) {
      if (silent) return;
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

  async function pollActiveRoom() {
    const roomCode = currentRoomCode();
    if (!roomCode || isPollingRoom) return;

    isPollingRoom = true;
    try {
      await refreshRoom(roomCode, { renderIfUnchanged: false, silent: true });
    } finally {
      isPollingRoom = false;
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

    const visibleRole = document.querySelector('.roleCard[data-round-started-at] .roleContent:not([hidden])');
    const revealedRound = visibleRole?.closest('.roleCard')?.dataset.roundStartedAt;

    if (route.name === 'room') app.innerHTML = roomPage(route.roomCode, roomCache.get(route.roomCode));
    else if (route.name === 'join') app.innerHTML = joinPage(route.roomCode);
    else app.innerHTML = homePage();

    if (revealedRound) {
      const roleCard = document.querySelector(`.roleCard[data-round-started-at="${revealedRound}"]`);
      const revealButton = roleCard?.querySelector('.revealButton');
      const roleContent = roleCard?.querySelector('.roleContent');
      if (revealButton && roleContent) {
        revealButton.hidden = true;
        roleContent.hidden = false;
      }
    }
  }

  function updateVisibleTimer() {
    const timer = document.querySelector('.timer[data-ends-at]');
    if (!timer) return;

    const endsAt = Number(timer.dataset.endsAt);
    const remainingSeconds = Math.max(0, Math.ceil((endsAt - Date.now()) / 1_000));
    const minutes = Math.floor(remainingSeconds / 60).toString().padStart(2, '0');
    const seconds = (remainingSeconds % 60).toString().padStart(2, '0');
    const value = timer.querySelector('[data-timer-value]');
    if (value) value.textContent = remainingSeconds === 0 ? "Time's up" : `${minutes}:${seconds}`;
    timer.classList.toggle('timerDone', remainingSeconds === 0);
    if (remainingSeconds === 0) timer.removeAttribute('data-ends-at');
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

    if (form.id === 'rename-player-form') {
      const roomCode = currentRoomCode();
      if (!roomCode) return;

      const playerName = new FormData(form).get('playerName')?.toString() ?? '';
      if (!playerName.trim()) return showError('rename-error', 'Enter a name.');

      try {
        await gameService.renamePlayer(roomCode, playerName);
        await refreshRoom(roomCode);
      } catch (error) {
        showError('rename-error', error instanceof Error ? error.message : 'Could not change your name.');
      }
    }

    if (form.id === 'remove-player-form') {
      const roomCode = currentRoomCode();
      if (!roomCode) return;

      const playerId = new FormData(form).get('playerId')?.toString() ?? '';
      if (!playerId) return showError('remove-error', 'Choose a player to remove.');

      try {
        await gameService.removePlayer(roomCode, playerId);
        await refreshRoom(roomCode);
      } catch (error) {
        showError('remove-error', error instanceof Error ? error.message : 'Could not remove player.');
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
      if (action === 'join-page') navigate(button.dataset.roomCode ? `/join/${button.dataset.roomCode}` : '/join');
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
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') pollActiveRoom();
    });
    window.addEventListener('popstate', render);
    window.addEventListener('focus', pollActiveRoom);
    window.setInterval(updateVisibleTimer, 1_000);
    window.setInterval(pollActiveRoom, 5_000);
    render();
  }

  return { start };
}
