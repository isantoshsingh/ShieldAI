const AI_DOMAINS = [
  "chat.openai.com",
  "platform.openai.com",
  "claude.ai",
  "gemini.google.com",
  "aistudio.google.com",
  "copilot.microsoft.com",
  "www.bing.com",
  "poe.com",
  "character.ai",
  "chat.mistral.ai",
  "grok.com",
  "meta.ai",
  "perplexity.ai",
  "you.com",
  "phind.com",
  "cursor.sh",
  "replit.com",
  "codeium.com",
  "app.tabnine.com",
  "bolt.new",
  "v0.dev",
  "midjourney.com",
  "firefly.adobe.com",
  "canva.com",
  "app.leonardo.ai",
  "jasper.ai",
  "copy.ai",
  "writesonic.com",
  "grammarly.com",
  "notion.so",
  "otter.ai",
  "runwayml.com",
  "elevenlabs.io",
  "suno.com",
  "lumalabs.ai"
];

(function () {
  const hostname = window.location.hostname;
  for (const domain of AI_DOMAINS) {
    if (hostname === domain || hostname.endsWith("." + domain)) {
      chrome.runtime.sendMessage({
        type: "AI_TOOL_DETECTED",
        domain: domain,
        pageTitle: document.title.slice(0, 255),
        detectedAt: new Date().toISOString()
      });
      break;
    }
  }
})();
