const tokenInput = document.getElementById("token");
const activateBtn = document.getElementById("activate");
const deactivateBtn = document.getElementById("deactivate");
const status = document.getElementById("status");

chrome.storage.local.get(["token"], (data) => {
  if (data.token) {
    status.textContent = "ShieldAI is active — token: " + data.token.slice(0, 8) + "…";
    status.className = "info";
  }
});

activateBtn.addEventListener("click", () => {
  const token = tokenInput.value.trim();
  if (!token) {
    status.textContent = "Please enter a token.";
    status.className = "error";
    return;
  }
  chrome.storage.local.set({ token: token, lastSent: {} }, () => {
    status.textContent = "Activated successfully.";
    status.className = "success";
  });
});

deactivateBtn.addEventListener("click", () => {
  chrome.storage.local.remove(["token", "lastSent"], () => {
    window.location.reload();
  });
});
