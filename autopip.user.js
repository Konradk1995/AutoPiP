// ==UserScript==
// @name         Auto PiP
// @namespace    https://github.com/Konradk1995/AutoPiP
// @version      1.0
// @description  Automatically enters Picture-in-Picture when you switch tabs or leave the browser.
// @author       Konrad Klonowski
// @match        *://*/*
// @run-at       document-idle
// @grant        none
// @inject-into  page
// @homepageURL  https://github.com/Konradk1995/AutoPiP
// @supportURL   https://github.com/Konradk1995/AutoPiP/issues
// @license      MIT
// ==/UserScript==

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
      // autoPictureInPicture still works, only pause override won't.
    }
  }
  window.__autoPipInjected = true;

  var target = null;
  var switching = false;
  var switchTimer;
  var rafPending = false;
  var nativePause = HTMLVideoElement.prototype.pause;

  function best() {
    var pick = null, high = 0;
    for (var v of document.querySelectorAll("video")) {
      if (!v.isConnected) continue;
      var s = (v.clientWidth * v.clientHeight) / 100;
      if (!v.paused && !v.ended) s += 1e4;
      if (v.readyState >= 2) s += 1e3;
      if (!v.muted) s += 500;
      if (s > high) { high = s; pick = v; }
    }
    return pick;
  }

  function release() {
    if (!target) return;
    target.autoPictureInPicture = false;
    delete target.pause;
    target = null;
  }

  function claim(v) {
    if (target === v) return;
    release();
    if (!v || !("autoPictureInPicture" in v)) return;
    v.autoPictureInPicture = true;
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

    if (v.requestPictureInPicture && !document.pictureInPictureElement)
      v.requestPictureInPicture().catch(function () {});

    if (v.webkitSupportsPresentationMode &&
        v.webkitSupportsPresentationMode("picture-in-picture") &&
        v.webkitPresentationMode !== "picture-in-picture")
      try { v.webkitSetPresentationMode("picture-in-picture"); } catch (_) {}
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
