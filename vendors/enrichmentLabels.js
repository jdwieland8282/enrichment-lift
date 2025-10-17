(function (w) {
  function computeLabels() {
    try {
      const el = w.pbjs?.getConfig?.('enrichmentLiftMeasurement') || {};
      const run = el?.testRun || 'DemoRun';
      const mods = el?.modules || [];

      const eids = w.pbjs?.getUserIdsAsEids?.() || [];
      const present = new Set(eids.map(e => e.source));

      // map User ID submodule -> EID source (extend if you add modules)
      const eidSourceFor = { sharedId: 'pubcid.org' };

      const arr = mods.map(m => ({
        name: m.name,
        percentage: m.percentage,
        enabled: present.has(eidSourceFor[m.name] || m.name)
      }));

      const labels = {};
      labels[run] = arr;

      // optional: expose for quick dev inspection
      w.pbjs = w.pbjs || {};
      w.pbjs._analyticsLabels = labels;

      return labels;
    } catch {
      return {};
    }
  }
  w.__computeEnrichmentLabels = computeLabels;
})(window);

