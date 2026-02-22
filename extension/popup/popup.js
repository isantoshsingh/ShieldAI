/**
 * ShieldAI Popup Script
 * Handles first-run onboarding and status display.
 */

const STORAGE_TOKEN_KEY = 'shieldai_token';
const API_BASE_URL = 'https://your-shieldai-app.onrender.com';

const loadingView    = document.getElementById('loading-view');
const onboardingView = document.getElementById('onboarding-view');
const activeView     = document.getElementById('active-view');
const emailInput     = document.getElementById('email-input');
const activateBtn    = document.getElementById('activate-btn');
const deactivateBtn  = document.getElementById('deactivate-btn');
const errorMsg       = document.getElementById('error-msg');
const userNameEl     = document.getElementById('user-name');
const userEmailEl    = document.getElementById('user-email');
const eventsCountEl  = document.getElementById('events-count');

function showView(view) {
  loadingView.style.display    = 'none';
  onboardingView.style.display = 'none';
  activeView.style.display     = 'none';
  view.style.display           = 'block';
}

function showError(message) {
  errorMsg.textContent = message;
  errorMsg.style.display = 'block';
}

function hideError() {
  errorMsg.style.display = 'none';
}

async function getStoredToken() {
  return new Promise((resolve) => {
    chrome.storage.local.get([STORAGE_TOKEN_KEY], (result) => {
      resolve(result[STORAGE_TOKEN_KEY] || null);
    });
  });
}

async function storeToken(token) {
  return new Promise((resolve) => {
    chrome.storage.local.set({ [STORAGE_TOKEN_KEY]: token }, resolve);
  });
}

async function clearToken() {
  return new Promise((resolve) => {
    chrome.storage.local.remove([STORAGE_TOKEN_KEY], resolve);
  });
}

async function fetchUserStatus(token) {
  const response = await fetch(`${API_BASE_URL}/api/v1/users/me?token=${encodeURIComponent(token)}`);
  if (!response.ok) throw new Error('Failed to fetch status');
  return response.json();
}

async function activateUser(email) {
  const response = await fetch(`${API_BASE_URL}/api/v1/users/activate`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body:    JSON.stringify({ email })
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error || `Server error (${response.status})`);
  }

  return response.json();
}

async function init() {
  const token = await getStoredToken();

  if (!token) {
    showView(onboardingView);
    return;
  }

  // Token exists — show active view and load stats
  showView(activeView);

  try {
    const data = await fetchUserStatus(token);
    userNameEl.textContent    = data.name || 'You';
    userEmailEl.textContent   = ''; // email not returned from /me for privacy
    eventsCountEl.textContent = data.events_7_days ?? '—';
  } catch {
    eventsCountEl.textContent = '—';
  }
}

activateBtn.addEventListener('click', async () => {
  const email = emailInput.value.trim();
  hideError();

  if (!email) {
    showError('Please enter your work email.');
    return;
  }

  activateBtn.disabled = true;
  activateBtn.textContent = 'Activating...';

  try {
    const data = await activateUser(email);
    await storeToken(data.token);

    userNameEl.textContent    = data.name || email.split('@')[0];
    userEmailEl.textContent   = email;
    eventsCountEl.textContent = '0';

    showView(activeView);
  } catch (err) {
    showError(err.message || 'Activation failed. Please try again.');
  } finally {
    activateBtn.disabled = false;
    activateBtn.textContent = 'Activate Monitoring';
  }
});

deactivateBtn.addEventListener('click', async () => {
  if (confirm('Remove ShieldAI from this device? Your historical data will be preserved.')) {
    await clearToken();
    emailInput.value = '';
    showView(onboardingView);
  }
});

// Start
init();
