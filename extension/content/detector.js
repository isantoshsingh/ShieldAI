/**
 * ShieldAI Content Script — detector.js
 * Runs on every page load. Checks if the current domain is an AI tool,
 * then fires an event to the Rails API if it matches.
 */

const STORAGE_TOKEN_KEY = 'shieldai_token';
const STORAGE_SESSION_KEY = 'shieldai_session_id';
const DEBOUNCE_PREFIX = 'shieldai_debounce_';
const DEBOUNCE_MS = 5 * 60 * 1000; // 5 minutes

const currentDomain = window.location.hostname;

/**
 * Generate or retrieve a stable session ID for this browser session.
 */
async function getOrCreateSessionId() {
  return new Promise((resolve) => {
    chrome.storage.session.get([STORAGE_SESSION_KEY], (result) => {
      if (result[STORAGE_SESSION_KEY]) {
        resolve(result[STORAGE_SESSION_KEY]);
      } else {
        const sessionId = crypto.randomUUID();
        chrome.storage.session.set({ [STORAGE_SESSION_KEY]: sessionId });
        resolve(sessionId);
      }
    });
  });
}

/**
 * Load the AI tools list from the extension's config file.
 */
async function loadAiTools() {
  const url = chrome.runtime.getURL('config/ai-tools.json');
  const response = await fetch(url);
  return response.json();
}

/**
 * Check if currentDomain matches any AI tool in the list.
 * Returns the matched tool object or null.
 */
function matchDomain(tools, domain) {
  return tools.find(tool => domain === tool.domain || domain.endsWith('.' + tool.domain)) || null;
}

/**
 * Check the debounce cache — only fire once per domain per 5 minutes.
 */
async function isDebounced(domain) {
  const key = DEBOUNCE_PREFIX + domain;
  return new Promise((resolve) => {
    chrome.storage.local.get([key], (result) => {
      const lastFired = result[key];
      if (lastFired && (Date.now() - lastFired) < DEBOUNCE_MS) {
        resolve(true);
      } else {
        chrome.storage.local.set({ [key]: Date.now() });
        resolve(false);
      }
    });
  });
}

/**
 * Get the user's API token from local storage.
 */
async function getToken() {
  return new Promise((resolve) => {
    chrome.storage.local.get([STORAGE_TOKEN_KEY], (result) => {
      resolve(result[STORAGE_TOKEN_KEY] || null);
    });
  });
}

/**
 * Get the API base URL from the background service worker.
 */
async function getApiBaseUrl() {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage({ type: 'GET_API_URL' }, (response) => {
      resolve(response?.url || 'https://your-shieldai-app.onrender.com');
    });
  });
}

/**
 * Send a detection event to the Rails API.
 */
async function sendEvent(token, sessionId, apiBaseUrl) {
  const payload = {
    token: token,
    event: {
      domain:      currentDomain,
      page_title:  document.title,
      detected_at: new Date().toISOString(),
      session_id:  sessionId
    }
  };

  try {
    const response = await fetch(`${apiBaseUrl}/api/v1/events`, {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify(payload)
    });

    if (!response.ok) {
      console.warn('[ShieldAI] Event post failed:', response.status);
    }
  } catch (err) {
    console.warn('[ShieldAI] Network error sending event:', err.message);
  }
}

/**
 * Open the popup so the user can enter their email for first-time setup.
 */
function requestTokenViaPopup() {
  chrome.runtime.sendMessage({ type: 'OPEN_POPUP' });
}

/**
 * Main detection flow.
 */
async function detect() {
  try {
    const tools = await loadAiTools();
    const matched = matchDomain(tools, currentDomain);

    if (!matched) return; // Not an AI tool — do nothing

    const debounced = await isDebounced(currentDomain);
    if (debounced) return; // Already fired recently

    const token = await getToken();
    if (!token) {
      requestTokenViaPopup();
      return;
    }

    const sessionId = await getOrCreateSessionId();
    const apiBaseUrl = await getApiBaseUrl();

    await sendEvent(token, sessionId, apiBaseUrl);
  } catch (err) {
    console.warn('[ShieldAI] Detection error:', err.message);
  }
}

detect();
