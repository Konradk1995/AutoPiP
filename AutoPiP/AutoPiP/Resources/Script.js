function show(enabled, useSettings, version) {
    if (typeof enabled === "boolean") {
        document.body.classList.toggle("state-on", enabled);
        document.body.classList.toggle("state-off", !enabled);
    }
    if (version) {
        document.getElementById("version").textContent = "v" + version;
    }
}

function showUpdate(version, url) {
    document.getElementById("update").style.display = "flex";
    document.getElementById("update-version").textContent = "v" + version;
    document.getElementById("update-btn").onclick = function () {
        webkit.messageHandlers.controller.postMessage("open-url:" + url);
    };
}

document.querySelector(".open-preferences").addEventListener("click", function () {
    webkit.messageHandlers.controller.postMessage("open-preferences");
});
