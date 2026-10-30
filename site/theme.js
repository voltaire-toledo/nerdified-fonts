(() => {
  const root = document.documentElement;
  const modes = ['light', 'dark', 'fun'];
  let mode = matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  let paused = matchMedia('(prefers-reduced-motion: reduce)').matches;
  try {
    const saved = localStorage.getItem('vt-nerdfonts-theme') || localStorage.getItem('font-validation-theme');
    if (modes.includes(saved)) mode = saved;
    if (localStorage.getItem('vt-nerdfonts-motion') === 'paused') paused = true;
  } catch {}
  root.dataset.theme = mode;
  root.dataset.motion = paused ? 'paused' : 'playing';
  function update() {
    const next = modes[(modes.indexOf(mode) + 1) % modes.length];
    document.querySelectorAll('[data-theme-toggle]').forEach(button => {
      button.textContent = `Theme: ${mode[0].toUpperCase() + mode.slice(1)}`;
      button.setAttribute('aria-label', `Current theme: ${mode}. Switch to ${next} theme`);
    });
    document.querySelectorAll('[data-motion-toggle]').forEach(button => {
      button.textContent = paused ? 'Play retro animations' : 'Pause retro animations';
      button.setAttribute('aria-pressed', String(paused));
    });
    document.querySelectorAll('[data-retro-image]').forEach(img => {
      img.src = mode === 'fun' && !paused ? 'images/retro-disk.gif' : 'images/retro-disk.png';
    });
  }
  document.addEventListener('DOMContentLoaded', () => {
    update();
    document.querySelectorAll('[data-theme-toggle]').forEach(button => button.addEventListener('click', () => {
      mode = modes[(modes.indexOf(mode) + 1) % modes.length];
      root.dataset.theme = mode;
      try { localStorage.setItem('vt-nerdfonts-theme', mode); } catch {}
      update();
    }));
    document.querySelectorAll('[data-motion-toggle]').forEach(button => button.addEventListener('click', () => {
      paused = !paused;
      root.dataset.motion = paused ? 'paused' : 'playing';
      try { localStorage.setItem('vt-nerdfonts-motion', paused ? 'paused' : 'playing'); } catch {}
      update();
    }));
    matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change', event => {
      if (event.matches) { paused = true; root.dataset.motion = 'paused'; update(); }
    });
  });
})();
