// vendors/patchGenericLabels.js
(function (w) {
  w.pbjs = w.pbjs || {}; w.pbjs.que = w.pbjs.que || [];
  w.pbjs.que.push(function () {
    try {
      // find the built-in 'generic' analytics adapter
      var reg = w.pbjs._analyticsRegistry && w.pbjs._analyticsRegistry.generic;
      if (!reg || typeof reg.track !== 'function') {
        console.warn('[labels-patch] generic analytics adapter not found');
        return;
      }
      var orig = reg.track;

      // wrap its track() to inject labels if missing
      reg.track = function (evt) {
        try {
          var labels = w.pbjs && w.pbjs._analyticsLabels;
          if (labels && Object.keys(labels).length) {
            evt.args = evt.args || {};
            // don't stomp if some events already have labels
            if (!evt.args.labels || !Object.keys(evt.args.labels).length) {
              evt.args.labels = labels;
            }
          }
        } catch (e) {
          // swallow
        }
        return orig.call(this, evt);
      };

      console.info('[labels-patch] generic analytics adapter patched');
    } catch (e) {
      console.warn('[labels-patch] patch failed', e);
    }
  });
})(window);
