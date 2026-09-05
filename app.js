// ===== Judgement Scorer - app logic (ES5, iOS Safari safe) =====

var STORAGE_GAME = 'judgement_current_game';
var STORAGE_HISTORY = 'judgement_history';

var setupState = {
  numPlayers: 4,
  names: ['A', 'B', 'C', 'D'],
  startCards: 7,
  dealerIndex: 0
};

var game = null;          // active game object
var undoStack = [];       // in-memory snapshots for undo
var currentEditRound = null;

// ---------- Utility ----------
function $(id) { return document.getElementById(id); }

function showScreen(id) {
  var screens = document.getElementsByClassName('screen');
  for (var i = 0; i < screens.length; i++) {
    screens[i].classList.remove('active');
  }
  $(id).classList.add('active');
  window.scrollTo(0, 0);
}

function openModal(id) { $(id).classList.add('active'); }
function closeModal(id) { $(id).classList.remove('active'); }

function showConfirm(title, body, onYes) {
  $('confirmModalTitle').textContent = title;
  $('confirmModalBody').textContent = body;
  var btn = $('confirmModalYes');
  var newBtn = btn.cloneNode(true);
  btn.parentNode.replaceChild(newBtn, btn);
  newBtn.addEventListener('click', function () {
    closeModal('confirmModal');
    onYes();
  });
  openModal('confirmModal');
}

function maxStartCards(n) {
  return Math.floor(104 / n);
}

function saveGame() {
  if (game) {
    try { localStorage.setItem(STORAGE_GAME, JSON.stringify(game)); } catch (e) {}
  }
}

function clearSavedGame() {
  try { localStorage.removeItem(STORAGE_GAME); } catch (e) {}
}

function loadSavedGame() {
  try {
    var raw = localStorage.getItem(STORAGE_GAME);
    if (raw) { return JSON.parse(raw); }
  } catch (e) {}
  return null;
}

function loadHistory() {
  try {
    var raw = localStorage.getItem(STORAGE_HISTORY);
    if (raw) { return JSON.parse(raw); }
  } catch (e) {}
  return [];
}

function saveHistory(list) {
  try { localStorage.setItem(STORAGE_HISTORY, JSON.stringify(list)); } catch (e) {}
}

function pushUndoSnapshot() {
  try {
    undoStack.push(JSON.stringify(game));
    if (undoStack.length > 15) { undoStack.shift(); }
  } catch (e) {}
}

// ---------- Home ----------
function initHome() {
  var saved = loadSavedGame();
  if (saved && saved.status === 'active') {
    $('btn-resume').style.display = 'block';
  } else {
    $('btn-resume').style.display = 'none';
  }
}

function resumeGame() {
  var saved = loadSavedGame();
  if (!saved) { return; }
  game = saved;
  routeToCurrentScreen();
}

function routeToCurrentScreen() {
  if (!game) { showScreen('screen-home'); return; }
  var round = currentRound();
  if (round.phase === 'announce') {
    renderAnnounceScreen();
  } else if (round.phase === 'actual') {
    renderActualScreen();
  } else if (round.phase === 'summary') {
    renderSummaryScreen();
  } else {
    renderAnnounceScreen();
  }
}

function currentRound() {
  return game.rounds[game.rounds.length - 1];
}

function confirmLeaveGame(target) {
  showConfirm('Leave Game?', 'Your progress is saved automatically. You can resume any time from Home.', function () {
    showScreen(target);
    initHome();
  });
}

// ---------- New Game Setup ----------
var STORAGE_NAME_HISTORY = 'judgement_name_history';

function loadNameHistory() {
  try {
    var raw = localStorage.getItem(STORAGE_NAME_HISTORY);
    if (raw) { return JSON.parse(raw); }
  } catch (e) {}
  return [];
}

function saveNameToHistory(name) {
  name = (name || '').trim();
  if (!name) { return; }
  var list = loadNameHistory();
  // remove any existing case-insensitive duplicate so the newest use moves to the top
  var filtered = [];
  for (var i = 0; i < list.length; i++) {
    if (list[i].toLowerCase() !== name.toLowerCase()) { filtered.push(list[i]); }
  }
  filtered.unshift(name);
  if (filtered.length > 40) { filtered = filtered.slice(0, 40); }
  try { localStorage.setItem(STORAGE_NAME_HISTORY, JSON.stringify(filtered)); } catch (e) {}
}

function goNewGame() {
  setupState.numPlayers = 4;
  setupState.names = ['', '', '', ''];
  setupState.startCards = Math.min(7, maxStartCards(4));
  setupState.dealerIndex = 0;
  renderSetupScreen();
  showScreen('screen-setup');
}

function renderSetupScreen() {
  $('playerCountVal').textContent = setupState.numPlayers;
  renderNameInputs();
  var mx = maxStartCards(setupState.numPlayers);
  $('maxCardsLabel').textContent = mx;
  if (setupState.startCards > mx) { setupState.startCards = mx; }
  if (setupState.startCards < 1) { setupState.startCards = 1; }
  $('startCardsVal').textContent = setupState.startCards;
  $('startCardsHint').textContent = setupState.numPlayers + ' players \u00D7 ' + setupState.startCards + ' cards = ' + (setupState.numPlayers * setupState.startCards) + ' of 104 cards';
  renderDealerChips();
}

function renderNameInputs() {
  var container = $('playerNamesContainer');
  container.innerHTML = '';
  while (setupState.names.length < setupState.numPlayers) {
    setupState.names.push('');
  }
  setupState.names = setupState.names.slice(0, setupState.numPlayers);
  var nameHistory = loadNameHistory();

  for (var i = 0; i < setupState.numPlayers; i++) {
    var row = document.createElement('div');
    row.className = 'name-input-row';
    row.style.position = 'relative';
    row.style.flexDirection = 'column';
    row.style.alignItems = 'stretch';

    var inputWrap = document.createElement('div');
    inputWrap.style.display = 'flex';
    inputWrap.style.alignItems = 'center';
    inputWrap.style.gap = '8px';

    var span = document.createElement('span');
    span.textContent = (i + 1) + '.';
    var input = document.createElement('input');
    input.type = 'text';
    input.value = setupState.names[i] || '';
    input.placeholder = 'Player ' + (i + 1) + ' name';
    input.autocomplete = 'off';
    input.autocapitalize = 'words';
    input.setAttribute('data-idx', i);

    var suggestBox = document.createElement('div');
    suggestBox.id = 'nameSuggest_' + i;
    suggestBox.style.display = 'none';
    suggestBox.style.position = 'absolute';
    suggestBox.style.top = '100%';
    suggestBox.style.left = '0';
    suggestBox.style.right = '0';
    suggestBox.style.zIndex = '20';
    suggestBox.style.background = '#0f2e20';
    suggestBox.style.border = '1px solid var(--border)';
    suggestBox.style.borderRadius = '10px';
    suggestBox.style.marginTop = '4px';
    suggestBox.style.maxHeight = '180px';
    suggestBox.style.overflowY = 'auto';

    function renderSuggestions(idx, filterText) {
      var box = $('nameSuggest_' + idx);
      var matches = [];
      var lower = filterText.toLowerCase();
      for (var h = 0; h < nameHistory.length; h++) {
        if (filterText === '' || nameHistory[h].toLowerCase().indexOf(lower) === 0) {
          if (nameHistory[h].toLowerCase() !== filterText.toLowerCase()) {
            matches.push(nameHistory[h]);
          }
        }
        if (matches.length >= 8) { break; }
      }
      if (matches.length === 0) {
        box.style.display = 'none';
        box.innerHTML = '';
        return;
      }
      box.innerHTML = '';
      for (var m = 0; m < matches.length; m++) {
        var item = document.createElement('div');
        item.textContent = matches[m];
        item.style.padding = '11px 14px';
        item.style.fontSize = '16px';
        item.style.borderBottom = (m < matches.length - 1) ? '1px solid var(--border)' : 'none';
        item.style.color = 'var(--text)';
        // mousedown fires before blur, so the value gets set before the field loses focus
        item.addEventListener('mousedown', function (ev) {
          ev.preventDefault();
          var chosen = ev.target.textContent;
          var targetInput = document.querySelector('input[data-idx="' + idx + '"]');
          targetInput.value = chosen;
          setupState.names[idx] = chosen;
          box.style.display = 'none';
          renderDealerChips();
        });
        box.appendChild(item);
      }
      box.style.display = 'block';
    }

    input.addEventListener('focus', function (e) {
      var idx = parseInt(e.target.getAttribute('data-idx'), 10);
      renderSuggestions(idx, e.target.value);
    });
    input.addEventListener('input', function (e) {
      var idx = parseInt(e.target.getAttribute('data-idx'), 10);
      setupState.names[idx] = e.target.value;
      renderDealerChips();
      renderSuggestions(idx, e.target.value);
    });
    input.addEventListener('blur', function (e) {
      var idx = parseInt(e.target.getAttribute('data-idx'), 10);
      setTimeout(function () {
        var box = $('nameSuggest_' + idx);
        if (box) { box.style.display = 'none'; }
      }, 120);
    });

    inputWrap.appendChild(span);
    inputWrap.appendChild(input);
    row.appendChild(inputWrap);
    row.appendChild(suggestBox);
    container.appendChild(row);
  }
}

function changePlayerCount(delta) {
  var n = setupState.numPlayers + delta;
  if (n < 2) { n = 2; }
  if (n > 15) { n = 15; }
  setupState.numPlayers = n;
  if (setupState.dealerIndex >= n) { setupState.dealerIndex = 0; }
  renderSetupScreen();
}

function changeStartCards(delta) {
  var mx = maxStartCards(setupState.numPlayers);
  var v = setupState.startCards + delta;
  if (v < 1) { v = 1; }
  if (v > mx) { v = mx; }
  setupState.startCards = v;
  $('startCardsVal').textContent = v;
  $('startCardsHint').textContent = setupState.numPlayers + ' players \u00D7 ' + v + ' cards = ' + (setupState.numPlayers * v) + ' of 104 cards';
}

function renderDealerChips() {
  var row = $('dealerChipRow');
  row.innerHTML = '';
  for (var i = 0; i < setupState.numPlayers; i++) {
    (function (idx) {
      var chip = document.createElement('div');
      chip.className = 'chip' + (setupState.dealerIndex === idx ? ' selected' : '');
      chip.textContent = setupState.names[idx] || ('Player ' + (idx + 1));
      chip.addEventListener('click', function () {
        setupState.dealerIndex = idx;
        renderDealerChips();
      });
      row.appendChild(chip);
    })(i);
  }
}

function buildAnnouncementOrder(dealerIndex, n) {
  var order = [];
  for (var i = 1; i <= n; i++) {
    order.push((dealerIndex + i) % n);
  }
  return order; // dealer ends up last automatically
}

function startGame() {
  var n = setupState.numPlayers;
  var players = [];
  for (var i = 0; i < n; i++) {
    var raw = (setupState.names[i] || '').trim();
    var nm = raw || ('Player ' + (i + 1));
    players.push({ id: i, name: nm, position: i });
    if (raw) { saveNameToHistory(raw); }
  }
  game = {
    gameId: 'g_' + Date.now(),
    date: new Date().toISOString(),
    numPlayers: n,
    players: players,
    startingCards: setupState.startCards,
    currentDealerIndex: setupState.dealerIndex,
    status: 'active',
    rounds: [],
    finalScores: null,
    winner: null
  };
  var round = createRound(1, setupState.startCards, setupState.dealerIndex);
  game.rounds.push(round);
  undoStack = [];
  saveGame();
  renderAnnounceScreen();
  showScreen('screen-announce');
}

function createRound(roundNumber, cardsPerPlayer, dealerIndex) {
  return {
    roundNumber: roundNumber,
    cardsPerPlayer: cardsPerPlayer,
    dealerIndex: dealerIndex,
    announcementOrder: buildAnnouncementOrder(dealerIndex, game ? game.numPlayers : setupState.numPlayers),
    announcements: {},
    results: {},
    roundScores: {},
    cumulativeScores: {},
    phase: 'announce'
  };
}

// ---------- Announcement Screen ----------
function renderAnnounceScreen() {
  var round = currentRound();
  $('announceRoundTitle').textContent = 'Round ' + round.roundNumber;
  $('announceCardsPerPlayer').textContent = round.cardsPerPlayer;
  var dealerName = game.players[round.dealerIndex].name;
  $('announceDealerName').textContent = dealerName;

  var list = $('announceList');
  list.innerHTML = '';

  for (var i = 0; i < round.announcementOrder.length; i++) {
    var playerIdx = round.announcementOrder[i];
    var player = game.players[playerIdx];
    var pill = document.createElement('div');
    pill.className = 'player-pill';

    var left = document.createElement('div');
    left.innerHTML = '<b>' + escapeHtml(player.name) + '</b>' + (playerIdx === round.dealerIndex ? ' <span class="badge">DEALER</span>' : '');
    pill.appendChild(left);

    var currentVal = (round.announcements[playerIdx] !== undefined ? round.announcements[playerIdx] : 0);
    round.announcements[playerIdx] = currentVal;

    var input = document.createElement('input');
    input.type = 'tel';
    input.inputMode = 'numeric';
    input.pattern = '[0-9]*';
    input.className = 'num-input';
    input.value = currentVal;
    input.setAttribute('data-player-idx', playerIdx);
    input.addEventListener('focus', function (e) { e.target.select(); });
    input.addEventListener('input', function (e) {
      var idx = parseInt(e.target.getAttribute('data-player-idx'), 10);
      var raw = e.target.value.replace(/[^0-9]/g, '');
      var v = raw === '' ? 0 : parseInt(raw, 10);
      var r = currentRound();
      if (v > r.cardsPerPlayer) { v = r.cardsPerPlayer; }
      r.announcements[idx] = v;
      updateAnnounceTotal();
      saveGame();
    });
    pill.appendChild(input);
    list.appendChild(pill);
  }

  updateAnnounceTotal();
}

function sumAnnouncedSoFar(round) {
  var sum = 0;
  for (var k in round.announcements) {
    if (round.announcements.hasOwnProperty(k)) { sum += round.announcements[k]; }
  }
  return sum;
}

function updateAnnounceTotal() {
  var round = currentRound();
  var total = sumAnnouncedSoFar(round);
  $('announceTotalVal').textContent = total;
  var warnDiv = $('announceWarning');
  if (total === round.cardsPerPlayer) {
    $('announceTotalVal').className = 'failed';
    warnDiv.innerHTML = '<div class="warning">Total announced equals ' + round.cardsPerPlayer + ' (cards per player) \u2014 this is not allowed. The dealer, ' + escapeHtml(game.players[round.dealerIndex].name) + ', must change their number.</div>';
  } else {
    $('announceTotalVal').className = '';
    warnDiv.innerHTML = '';
  }
}

function confirmAllAnnouncements() {
  var round = currentRound();
  var total = sumAnnouncedSoFar(round);
  if (total === round.cardsPerPlayer) {
    updateAnnounceTotal();
    return; // blocked, warning already shown
  }
  round.phase = 'actual';
  saveGame();
  renderActualScreen();
  showScreen('screen-actual');
}

// ---------- Actual Sets Screen (Win / Lost toggle) ----------
var actualTemp = {}; // playerIdx -> 'win' | 'lost'

function renderActualScreen() {
  var round = currentRound();
  $('actualRoundTitle').textContent = 'Round ' + round.roundNumber;
  $('actualCardsPerPlayer').textContent = round.cardsPerPlayer;
  $('actualTotalAnnounced').textContent = sumAnnouncedSoFar(round);

  // preload from saved results if resuming, else default everyone to 'win'
  actualTemp = {};
  for (var i0 = 0; i0 < game.players.length; i0++) {
    if (round.results && round.results[i0]) {
      actualTemp[i0] = round.results[i0];
    } else {
      actualTemp[i0] = 'win';
    }
  }

  var list = $('actualList');
  list.innerHTML = '';
  for (var i = 0; i < game.players.length; i++) {
    var player = game.players[i];
    var announced = round.announcements[i];
    var pill = document.createElement('div');
    pill.className = 'player-pill';

    var left = document.createElement('div');
    left.innerHTML = '<b>' + escapeHtml(player.name) + '</b><br><span class="small-muted">announced ' + announced + '</span>';
    pill.appendChild(left);

    var toggleWrap = document.createElement('div');
    toggleWrap.className = 'wl-toggle';
    toggleWrap.id = 'wltoggle_' + i;
    toggleWrap.style.minWidth = '160px';
    toggleWrap.innerHTML =
      '<button class="wl-btn" id="winbtn_' + i + '" onclick="setActualResult(' + i + ',\'win\')">Win</button>' +
      '<button class="wl-btn" id="lostbtn_' + i + '" onclick="setActualResult(' + i + ',\'lost\')">Lost</button>';
    pill.appendChild(toggleWrap);
    list.appendChild(pill);
    refreshToggleUI(i);
  }
}

function setActualResult(playerIdx, result) {
  actualTemp[playerIdx] = result;
  refreshToggleUI(playerIdx);
}

function refreshToggleUI(playerIdx) {
  var winBtn = $('winbtn_' + playerIdx);
  var lostBtn = $('lostbtn_' + playerIdx);
  if (!winBtn || !lostBtn) { return; }
  winBtn.className = 'wl-btn' + (actualTemp[playerIdx] === 'win' ? ' win-selected' : '');
  lostBtn.className = 'wl-btn' + (actualTemp[playerIdx] === 'lost' ? ' lost-selected' : '');
}

function finishRound() {
  var round = currentRound();
  round.results = {};
  for (var i = 0; i < game.players.length; i++) {
    round.results[i] = actualTemp[i] || 'win';
  }
  computeRoundScores(round);
  round.phase = 'summary';
  pushUndoSnapshot();
  saveGame();
  renderSummaryScreen();
  showScreen('screen-summary');
}

// Computes roundScores + cumulativeScores for a round from its announcements/results,
// using the cumulative totals of the previous round (or 0 for round 1) as the base.
function computeRoundScores(round) {
  var roundIndexInArray = -1;
  for (var ri = 0; ri < game.rounds.length; ri++) {
    if (game.rounds[ri].roundNumber === round.roundNumber) { roundIndexInArray = ri; break; }
  }
  var prevCumulative = {};
  if (roundIndexInArray > 0) {
    prevCumulative = game.rounds[roundIndexInArray - 1].cumulativeScores;
  } else {
    for (var p = 0; p < game.players.length; p++) { prevCumulative[p] = 0; }
  }
  for (var i = 0; i < game.players.length; i++) {
    var announced = round.announcements[i];
    var won = round.results[i] === 'win';
    var score = won ? (10 + announced) : (-announced);
    round.roundScores[i] = score;
    round.cumulativeScores[i] = (prevCumulative[i] || 0) + score;
  }
}

// ---------- Round Summary ----------
function renderSummaryScreen() {
  var round = currentRound();
  $('summaryRoundTitle').textContent = 'Round ' + round.roundNumber + ' Result';

  var tbody = document.querySelector('#summaryTable tbody');
  tbody.innerHTML = '';
  for (var i = 0; i < round.announcementOrder.length; i++) {
    var idx = round.announcementOrder[i];
    var player = game.players[idx];
    var announced = round.announcements[idx];
    var won = round.results[idx] === 'win';
    var score = round.roundScores[idx];
    var tr = document.createElement('tr');
    tr.innerHTML = '<td>' + escapeHtml(player.name) + '</td><td>' + announced + '</td>' +
      '<td class="' + (won ? 'success' : 'failed') + '">' + (won ? 'WIN' : 'LOST') + '</td>' +
      '<td class="' + (score >= 0 ? 'success' : 'failed') + '">' + (score >= 0 ? '+' : '') + score + '</td>';
    tbody.appendChild(tr);
  }

  $('summaryStandingsTable').innerHTML = generateScoreMatrixHtml();

  var isLastRound = round.cardsPerPlayer === 1;
  $('nextRoundBtn').textContent = isLastRound ? 'Finish Game' : 'Next Round';
}

// Builds a full round-by-round score matrix: one row per round played so far,
// one column per player, plus a bolded running Total row at the bottom.
function generateScoreMatrixHtml() {
  var playedRounds = [];
  for (var i = 0; i < game.rounds.length; i++) {
    if (Object.keys(game.rounds[i].roundScores).length > 0) { playedRounds.push(game.rounds[i]); }
  }

  var html = '<thead><tr><th style="text-align:left;">Round</th>';
  for (var p = 0; p < game.players.length; p++) {
    html += '<th>' + escapeHtml(game.players[p].name) + '</th>';
  }
  html += '</tr></thead><tbody>';

  for (var r = 0; r < playedRounds.length; r++) {
    var round = playedRounds[r];
    html += '<tr><td style="text-align:left; color:var(--text-dim); white-space:nowrap;">R' + round.roundNumber + ' <span class="small-muted">(' + round.cardsPerPlayer + 'c)</span></td>';
    for (var pi = 0; pi < game.players.length; pi++) {
      var sc = round.roundScores[pi];
      var cls = sc >= 0 ? 'success' : 'failed';
      html += '<td class="' + cls + '">' + (sc >= 0 ? '+' : '') + sc + '</td>';
    }
    html += '</tr>';
  }

  var totals = {};
  for (var t = 0; t < game.players.length; t++) { totals[t] = 0; }
  if (playedRounds.length > 0) {
    totals = playedRounds[playedRounds.length - 1].cumulativeScores;
  }
  var topScore = -Infinity;
  for (var tt = 0; tt < game.players.length; tt++) {
    var v = totals[tt] || 0;
    if (v > topScore) { topScore = v; }
  }
  html += '<tr style="border-top:2px solid var(--gold);"><td style="text-align:left; font-weight:800; color:var(--gold);">TOTAL</td>';
  for (var ti = 0; ti < game.players.length; ti++) {
    var val = totals[ti] || 0;
    var isLeader = (val === topScore);
    html += '<td style="font-weight:800;" class="' + (isLeader ? 'leader' : '') + '">' + val + (isLeader ? ' \u2B50' : '') + '</td>';
  }
  html += '</tr></tbody>';
  return html;
}

function goNextRound() {
  var round = currentRound();
  if (round.cardsPerPlayer === 1) {
    finishGame();
    return;
  }
  var nextDealer = (round.dealerIndex + 1) % game.numPlayers;
  var nextCards = round.cardsPerPlayer - 1;
  var nextRound = createRound(round.roundNumber + 1, nextCards, nextDealer);
  game.rounds.push(nextRound);
  game.currentDealerIndex = nextDealer;
  saveGame();
  renderAnnounceScreen();
  showScreen('screen-announce');
}

function undoLastRound() {
  showConfirm('Undo Last Round?', 'This will remove the most recently submitted round result so you can re-enter it.', function () {
    if (undoStack.length > 0) {
      var snapshot = undoStack.pop();
      game = JSON.parse(snapshot);
      saveGame();
      routeToCurrentScreen();
    } else {
      // fallback: revert current round back to win/lost entry phase
      var round = currentRound();
      round.phase = 'actual';
      round.roundScores = {};
      round.cumulativeScores = {};
      round.results = {};
      saveGame();
      renderActualScreen();
      showScreen('screen-actual');
    }
  });
}

// ---------- Game Finished ----------
function finishGame() {
  var round = currentRound();
  game.status = 'finished';
  game.finalScores = round.cumulativeScores;
  var arr = [];
  for (var i = 0; i < game.players.length; i++) {
    arr.push({ idx: i, name: game.players[i].name, score: round.cumulativeScores[i] || 0 });
  }
  arr.sort(function (a, b) { return b.score - a.score; });
  var topScore = arr.length ? arr[0].score : 0;
  var winners = [];
  for (var j = 0; j < arr.length; j++) {
    if (arr[j].score === topScore) { winners.push(arr[j].name); }
  }
  game.winner = winners;
  saveGame();
  renderFinishedScreen(arr, winners);
  showScreen('screen-finished');
}

function renderFinishedScreen(arr, winners) {
  $('finishedWinnerText').textContent = winners.length > 1 ? ('Tied: ' + winners.join(' & ')) : winners[0];
  var tbody = document.querySelector('#finalScoresTable tbody');
  tbody.innerHTML = '';
  for (var i = 0; i < arr.length; i++) {
    var isWinner = arr[i].score === arr[0].score;
    var tr = document.createElement('tr');
    tr.innerHTML = '<td>' + (i + 1) + '.</td><td class="' + (isWinner ? 'leader' : '') + '">' + escapeHtml(arr[i].name) + (isWinner ? ' \uD83C\uDFC6' : '') + '</td><td class="' + (isWinner ? 'leader' : '') + '">' + arr[i].score + '</td>';
    tbody.appendChild(tr);
  }
}

function goToHomeAfterFinish() {
  var history = loadHistory();
  history.unshift(JSON.parse(JSON.stringify(game)));
  saveHistory(history);
  clearSavedGame();
  game = null;
  undoStack = [];
  initHome();
  showScreen('screen-home');
}

function viewCurrentGameDetail() {
  openHistoryDetail(game, true);
}

// ---------- Scoreboard modal ----------
function showScoreboardModal() {
  $('modalScoreTable').innerHTML = generateScoreMatrixHtml();
  openModal('scoreboardModal');
}

// ---------- History ----------
function renderHistoryList() {
  var history = loadHistory();
  var container = $('historyList');
  var empty = $('historyEmpty');
  container.innerHTML = '';
  if (history.length === 0) {
    empty.style.display = 'block';
    return;
  }
  empty.style.display = 'none';
  for (var i = 0; i < history.length; i++) {
    (function (g) {
      var item = document.createElement('div');
      item.className = 'history-item';
      var d = new Date(g.date);
      var dateStr = d.toLocaleDateString();
      var winnerStr = g.winner ? g.winner.join(' & ') : '-';
      item.innerHTML = '<div><b>' + dateStr + '</b><div class="meta">' + g.players.length + ' players &middot; started ' + g.startingCards + ' cards &middot; won by ' + escapeHtml(winnerStr) + '</div></div><div>&#8250;</div>';
      item.addEventListener('click', function () { openHistoryDetail(g, false); });
      container.appendChild(item);
      if (i < history.length - 1) {
        var div = document.createElement('div');
        div.className = 'divider';
        div.style.margin = '0';
        container.appendChild(div);
      }
    })(history[i]);
  }
}

function openHistoryDetail(g, isLive) {
  $('detailTitle').textContent = new Date(g.date).toLocaleDateString() + (isLive ? ' (in progress)' : '');
  var content = $('detailContent');
  content.innerHTML = '';

  var summaryCard = document.createElement('div');
  summaryCard.className = 'card';
  summaryCard.innerHTML = '<div class="row"><span class="small-muted">Players</span><b>' + g.players.map(function (p) { return escapeHtml(p.name); }).join(', ') + '</b></div>' +
    '<div class="row"><span class="small-muted">Starting cards</span><b>' + g.startingCards + '</b></div>' +
    '<div class="row"><span class="small-muted">Winner</span><b>' + (g.winner ? escapeHtml(g.winner.join(' & ')) : '-') + '</b></div>';
  content.appendChild(summaryCard);

  for (var r = 0; r < g.rounds.length; r++) {
    var round = g.rounds[r];
    if (Object.keys(round.roundScores).length === 0) { continue; }
    var card = document.createElement('div');
    card.className = 'card';
    var header = document.createElement('div');
    header.className = 'row';
    header.innerHTML = '<h2 style="margin:0;">Round ' + round.roundNumber + ' \u2014 ' + round.cardsPerPlayer + ' cards</h2>';
    if (isLive) {
      var editBtn = document.createElement('button');
      editBtn.className = 'btn-sm btn-secondary';
      editBtn.textContent = 'Edit';
      editBtn.onclick = (function (roundNum) { return function () { openEditRound(roundNum); }; })(round.roundNumber);
      header.appendChild(editBtn);
    }
    card.appendChild(header);

    var table = document.createElement('table');
    var tbody = document.createElement('tbody');
    var thead = document.createElement('thead');
    thead.innerHTML = '<tr><th>Player</th><th>Ann</th><th>Outcome</th><th>Score</th><th>Total</th></tr>';
    table.appendChild(thead);
    for (var i = 0; i < g.players.length; i++) {
      var announced = round.announcements[i];
      var won = round.results[i] === 'win';
      var score = round.roundScores[i];
      var cum = round.cumulativeScores[i];
      var tr = document.createElement('tr');
      tr.innerHTML = '<td>' + escapeHtml(g.players[i].name) + '</td><td>' + announced + '</td>' +
        '<td class="' + (won ? 'success' : 'failed') + '">' + (won ? 'WIN' : 'LOST') + '</td>' +
        '<td class="' + (score >= 0 ? 'success' : 'failed') + '">' + (score >= 0 ? '+' : '') + score + '</td><td>' + cum + '</td>';
      tbody.appendChild(tr);
    }
    table.appendChild(tbody);
    card.appendChild(table);
    content.appendChild(card);
  }
  showScreen('screen-history-detail');
}

// ---------- Edit Round ----------
function openEditRound(roundNumber) {
  currentEditRound = roundNumber;
  var round = null;
  for (var i = 0; i < game.rounds.length; i++) {
    if (game.rounds[i].roundNumber === roundNumber) { round = game.rounds[i]; break; }
  }
  if (!round) { return; }
  $('editRoundNum').textContent = roundNumber;
  editTempResults = {};
  var body = $('editRoundBody');
  body.innerHTML = '';
  for (var p = 0; p < game.players.length; p++) {
    editTempResults[p] = round.results[p] === 'lost' ? 'lost' : 'win';
    var wrap = document.createElement('div');
    wrap.style.marginBottom = '14px';
    wrap.innerHTML = '<label>' + escapeHtml(game.players[p].name) + '</label>' +
      '<input type="number" min="0" id="editAnn_' + p + '" value="' + round.announcements[p] + '" placeholder="Announced" style="margin-bottom:8px;">' +
      '<div class="wl-toggle">' +
      '<button type="button" class="wl-btn" id="editwin_' + p + '" onclick="setEditResult(' + p + ',\'win\')">Win</button>' +
      '<button type="button" class="wl-btn" id="editlost_' + p + '" onclick="setEditResult(' + p + ',\'lost\')">Lost</button>' +
      '</div>';
    body.appendChild(wrap);
    refreshEditToggleUI(p);
  }
  openModal('editRoundModal');
}

var editTempResults = {};

function setEditResult(playerIdx, result) {
  editTempResults[playerIdx] = result;
  refreshEditToggleUI(playerIdx);
}

function refreshEditToggleUI(playerIdx) {
  var winBtn = $('editwin_' + playerIdx);
  var lostBtn = $('editlost_' + playerIdx);
  if (!winBtn || !lostBtn) { return; }
  winBtn.className = 'wl-btn' + (editTempResults[playerIdx] === 'win' ? ' win-selected' : '');
  lostBtn.className = 'wl-btn' + (editTempResults[playerIdx] === 'lost' ? ' lost-selected' : '');
}

function saveEditedRound() {
  var round = null;
  for (var i = 0; i < game.rounds.length; i++) {
    if (game.rounds[i].roundNumber === currentEditRound) { round = game.rounds[i]; break; }
  }
  if (!round) { closeModal('editRoundModal'); return; }

  pushUndoSnapshot();

  var total = 0;
  var newAnn = {};
  var newResults = {};
  for (var p = 0; p < game.players.length; p++) {
    var a = parseInt($('editAnn_' + p).value, 10);
    if (isNaN(a) || a < 0) { a = 0; }
    newAnn[p] = a;
    newResults[p] = editTempResults[p] === 'lost' ? 'lost' : 'win';
    total += a;
  }
  if (total === round.cardsPerPlayer) {
    alert('Total announced cannot equal cards per player (' + round.cardsPerPlayer + '). Adjust one value.');
    return;
  }
  round.announcements = newAnn;
  round.results = newResults;

  // recompute this round and all following played rounds' scores/cumulative
  var roundIndexInArray = -1;
  for (var ri = 0; ri < game.rounds.length; ri++) {
    if (game.rounds[ri].roundNumber === currentEditRound) { roundIndexInArray = ri; break; }
  }
  for (var ridx = roundIndexInArray; ridx < game.rounds.length; ridx++) {
    var rObj = game.rounds[ridx];
    if (Object.keys(rObj.roundScores).length === 0) { break; } // not yet played, stop
    computeRoundScores(rObj);
  }

  // if game already finished, update final scores too
  if (game.status === 'finished') {
    var lastRound = game.rounds[game.rounds.length - 1];
    game.finalScores = lastRound.cumulativeScores;
    var arr = [];
    for (var pi = 0; pi < game.players.length; pi++) {
      arr.push({ idx: pi, name: game.players[pi].name, score: lastRound.cumulativeScores[pi] || 0 });
    }
    arr.sort(function (a, b) { return b.score - a.score; });
    var top = arr.length ? arr[0].score : 0;
    var winners = [];
    for (var wi = 0; wi < arr.length; wi++) { if (arr[wi].score === top) { winners.push(arr[wi].name); } }
    game.winner = winners;
  }

  saveGame();
  closeModal('editRoundModal');
  openHistoryDetail(game, true);
}

// ---------- Helpers ----------
function escapeHtml(str) {
  if (str === undefined || str === null) { return ''; }
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ---------- History screen nav hook ----------
var origShowScreen = showScreen;
showScreen = function (id) {
  origShowScreen(id);
  if (id === 'screen-history') { renderHistoryList(); }
  if (id === 'screen-home') { initHome(); }
};

// ---------- Init ----------
window.addEventListener('load', function () {
  initHome();
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(function (e) {});
  }
});
