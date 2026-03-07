const API_URL = "https://REPLACE_WITH_SHIELDAI_HOST/api/v1/detection_events";

chrome.runtime.onMessage.addListener((message, _sender, _sendResponse) => {
  if (message.type !== "AI_TOOL_DETECTED") return;

  chrome.storage.local.get(["token", "lastSent"], (data) => {
    const token = data.token;
    if (!token) return;

    const lastSent = data.lastSent || {};
    const now = Date.now();

    if (lastSent[message.domain] && now - lastSent[message.domain] < 30 * 60 * 1000) {
      return;
    }

    fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        token: token,
        domain: message.domain,
        page_title: message.pageTitle,
        detected_at: message.detectedAt
      })
    })
      .then((response) => {
        if (response.status === 201) {
          lastSent[message.domain] = now;
          chrome.storage.local.set({ lastSent: lastSent });
        }
      })
      .catch(() => {});
  });
});
