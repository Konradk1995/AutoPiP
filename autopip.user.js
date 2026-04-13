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

(function () {
  "use strict";

  let target = null;
  let switching = false;
  let switchTimer;
  let rafPending = false;
  const nativePause = HTMLVideoElement.prototype.pause;

  function best() {
    let pick = null, high = 0;
    for (const v of document.querySelectorAll("video")) {
      if (!v.isConnected) continue;
      let s = (v.clientWidth * v.clientHeight) / 100;
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
    delete target.pause; // restore prototype method
    target = null;
  }

  function claim(v) {
    if (target === v) return;
    release();
    if (!v || !("autoPictureInPicture" in v)) return;
    v.autoPictureInPicture = true;
    // Instance-level pause override — only this video, not the prototype.
    // Sites call video.pause() on visibilitychange which kills playback
    // before Safari can enter PiP. We block it during the switch window
    // and while the video is actively in a PiP presentation.
    v.pause = function () {
      const pip = this.webkitPresentationMode === "picture-in-picture" ||
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
    let v = target;
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
