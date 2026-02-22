/**
 * ShieldAI Background Service Worker
 * Handles messages from content scripts and manages extension state.
 */

const API_BASE_URL = 'https://your-shieldai-app.onrender.com';

// Listen for messages from content scripts and popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case 'GET_API_URL':
      sendResponse({ url: API_BASE_URL });
      break;

    case 'OPEN_POPUP':
      // Open the extension popup by focusing the extension icon
      // This triggers the browser action which opens popup.html
      chrome.action.openPopup().catch(() => {
        // openPopup may fail if not triggered by a user gesture — ignore
      });
      sendResponse({ ok: true });
      break;

    case 'GET_STATUS':
      chrome.storage.local.get(['shieldai_token'], (result) => {
        sendResponse({
          active: !!result.shieldai_token,
          token:  result.shieldai_token || null
        });
      });
      return true; // Keep message channel open for async response

    default:
      sendResponse({ error: 'Unknown message type' });
  }

  return false;
});

// On install, open the popup so users can enter their email
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    chrome.tabs.create({
      url: chrome.runtime.getURL('popup/popup.html') + '?onboarding=true'
    });
  }
});
