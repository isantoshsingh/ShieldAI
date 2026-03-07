# ShieldAI Chrome Extension

Chrome MV3 extension that silently detects employee visits to known AI tool domains and reports them to the ShieldAI API.

## What It Does

- Detects visits to 35 known AI tool domains (ChatGPT, Claude, Gemini, Midjourney, etc.)
- Sends the domain name and page title to the ShieldAI API
- Deduplicates events: same domain is only reported once per 30 minutes
- Does **not** read page content, prompts, form values, or keystrokes
- Does **not** block access to any website

## Files

```
shieldai-extension/
├── manifest.json   — MV3 extension configuration
├── content.js      — Content script that detects AI tool domains on page load
├── background.js   — Service worker that deduplicates and POSTs events to the API
├── setup.html      — Employee onboarding page for entering their token
└── setup.js        — JavaScript for the setup page
```

## Configuration

Before distributing the extension, update the `API_URL` in `background.js`:

```javascript
// Replace with your ShieldAI host
const API_URL = "https://your-shieldai-host.com/api/v1/detection_events";
```

## Installation (Development)

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top-right)
3. Click **Load unpacked**
4. Select the `shieldai-extension/` folder

## Employee Setup

1. After installing, right-click the ShieldAI extension icon and select **Options** (or navigate to `chrome-extension://<id>/setup.html`)
2. Enter the employee's `extension_token` (provided by their org admin)
3. Click **Activate**
4. The status message will confirm activation

To deactivate, open the options page and click **Deactivate**.

## How It Works

1. **content.js** runs on every page load. It checks `window.location.hostname` against 35 hardcoded AI tool domains. On a match, it sends a message to the background service worker with the domain, page title, and timestamp.

2. **background.js** receives the message and:
   - Reads the employee's token from `chrome.storage.local`
   - Checks if the same domain was already reported in the last 30 minutes (deduplication)
   - If not a duplicate, POSTs to the API: `{ token, domain, page_title, detected_at }`
   - On success (201), records the send time to prevent duplicates
   - On any error, fails silently — no retries, no user-facing errors

3. The Rails API (`POST /api/v1/detection_events`) validates the token, finds the employee's organisation, matches the domain to an AI tool, and creates a detection event record.

## Monitored Domains

The extension monitors these AI tool domains:

| Category | Domains |
|----------|---------|
| Chat | chat.openai.com, platform.openai.com, claude.ai, gemini.google.com, aistudio.google.com, copilot.microsoft.com, www.bing.com, poe.com, character.ai, chat.mistral.ai, grok.com, meta.ai |
| Search | perplexity.ai, you.com |
| Code | phind.com, cursor.sh, replit.com, codeium.com, app.tabnine.com, bolt.new, v0.dev |
| Image | midjourney.com, firefly.adobe.com, canva.com, app.leonardo.ai |
| Writing | jasper.ai, copy.ai, writesonic.com, grammarly.com, notion.so |
| Other | otter.ai, runwayml.com, elevenlabs.io, suno.com, lumalabs.ai |

## Token Regeneration

If an employee's token is compromised, the org admin can regenerate it from the Employees page in the dashboard. The employee must then update their extension with the new token via the setup page.

## Permissions

| Permission | Reason |
|------------|--------|
| `storage` | Store the employee token and deduplication timestamps locally |
| `<all_urls>` (host) | Content script must run on all pages to detect AI tool domains |
