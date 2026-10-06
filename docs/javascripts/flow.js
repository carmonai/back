/* =============================================================================
   Diagram runtime.

   Two jobs, both small:

   1. SMIL animations (<animate>) cannot be switched off from CSS, so under
      `prefers-reduced-motion: reduce` we pause them and place the element at its
      end state — the diagram keeps its full meaning, it just stops moving.
   2. Mermaid renders its SVG in the page's own colours. Material rebuilds the page
      on instant navigation, so Mermaid has to be told about it through the
      documented `document$` observable rather than a plain DOMContentLoaded hook.
   ============================================================================= */

(function () {
  "use strict";

  var REDUCED = window.matchMedia("(prefers-reduced-motion: reduce)");

  /** Pause SMIL and park each animated element where the animation would have ended. */
  function settleSmil(root) {
    var animations = root.querySelectorAll("animate, animateMotion, animateTransform");
    animations.forEach(function (node) {
      try {
        if (node.animations) {
          node.animations.forEach(function (a) {
            a.pause();
            a.currentTime = 0;
          });
        } else if (typeof node.endElement === "function") {
          node.endElement();
        }
      } catch (e) {
        /* An engine that will not let us pause it simply keeps animating. */
      }
    });
  }

  /** Start or stop SMIL when the reader's preference changes, without a reload. */
  function applyPreference() {
    if (!REDUCED.matches) return;
    settleSmil(document);
  }

  function onReady() {
    applyPreference();
  }

  if (typeof REDUCED.addEventListener === "function") {
    REDUCED.addEventListener("change", function () {
      if (REDUCED.matches) settleSmil(document);
      else window.location.reload();
    });
  }

  // Material's instant navigation swaps the document; `document$` fires for every
  // page it renders, which is why this is not a DOMContentLoaded handler.
  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(onReady);
  } else {
    document.addEventListener("DOMContentLoaded", onReady);
  }
})();
