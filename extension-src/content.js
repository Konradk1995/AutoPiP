// Auto PiP — core logic. Runs in main world (page context).
// When loaded as a userscript in an isolated world, the wrapper injects
// itself into the page via <script> tag so pause() override works.
// When loaded as a native Safari extension (manifest "world": "MAIN"), runs directly.

(function autoPiP() {
  "use strict";

  if (window.__autoPipInjected) return;

  // Detect isolated content-script world and re-inject into main world.
  if (document.head && !document.querySelector("script[data-autopip]")) {
    try {
      var s = document.createElement("script");
      s.dataset.autopip = "1";
      s.textContent = "(" + autoPiP.toString() + ")()";
      document.head.appendChild(s);
      s.remove();
      return;
    } catch (_) {
      // CSP blocks inline scripts — fall through, run in isolated world.
    }
  }
  window.__autoPipInjected = true;

  // --- Top-frame only: grant PiP permission to all iframes ---
  if (window === window.top) {
    var PIP_ALLOW = "picture-in-picture; autoplay; fullscreen";
    function patchIframes() {
      var frames = document.querySelectorAll("iframe");
      for (var i = 0; i < frames.length; i++) {
        var f = frames[i];
        if (!f.allow || f.allow.indexOf("picture-in-picture") === -1) {
          f.allow = f.allow ? f.allow + "; " + PIP_ALLOW : PIP_ALLOW;
        }
        if (!f.allowFullscreen) f.allowFullscreen = true;
      }
    }
    patchIframes();
    new MutationObserver(patchIframes).observe(
      document.body || document.documentElement,
      { childList: true, subtree: true }
    );
  }

  // --- PiP logic (runs in every frame) ---
  var target = null;
  var switching = false;
  var switchTimer;
  var rafPending = false;
  var nativePause = HTMLVideoElement.prototype.pause;

  function best() {
    var pick = null, high = 0;
    var videos = document.querySelectorAll("video");
    for (var i = 0; i < videos.length; i++) {
      var v = videos[i];
      if (!v.isConnected) continue;
      var score = (v.clientWidth * v.clientHeight) / 100;
      if (!v.paused && !v.ended) score += 1e4;
      if (v.readyState >= 2) score += 1e3;
      if (!v.muted) score += 500;
      if (score > high) { high = score; pick = v; }
    }
    return pick;
  }

  function release() {
    if (!target) return;
    try { target.autoPictureInPicture = false; } catch (_) {}
    delete target.pause;
    target = null;
  }

  function claim(v) {
    if (target === v) return;
    release();
    if (!v) return;
    try { v.autoPictureInPicture = true; } catch (_) {}
    v.pause = function () {
      var pip = this.webkitPresentationMode === "picture-in-picture" ||
                document.pictureInPictureElement === this;
      if (switching || (pip && document.visibilityState === "hidden")) return;
      return nativePause.apply(this, arguments);
    };
    target = v;
  }

  function sync() {
    if (target && !target.isConnected) release();
    claim(best());
  }

  function lazy() {
    if (rafPending) return;
    rafPending = true;
    requestAnimationFrame(function () { rafPending = false; sync(); });
  }

  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState !== "hidden") {
      switching = false;
      clearTimeout(switchTimer);
      return;
    }
    var v = target;
    if (!v) { v = best(); claim(v); }
    if (!v || v.paused) return;

    switching = true;
    clearTimeout(switchTimer);
    switchTimer = setTimeout(function () { switching = false; }, 1500);

    // Try standard PiP API
    if (v.requestPictureInPicture && !document.pictureInPictureElement) {
      v.requestPictureInPicture().catch(function () {});
    }
    // Try Safari webkit PiP API
    if (v.webkitSupportsPresentationMode &&
        v.webkitSupportsPresentationMode("picture-in-picture") &&
        v.webkitPresentationMode !== "picture-in-picture") {
      try { v.webkitSetPresentationMode("picture-in-picture"); } catch (_) {}
    }
  }, true);

  sync();
  new MutationObserver(lazy).observe(
    document.body || document.documentElement,
    { childList: true, subtree: true }
  );
  document.addEventListener("play", sync, true);
  document.addEventListener("pause", sync, true);
  document.addEventListener("loadeddata", sync, true);
  setInterval(sync, 5000);
})();
