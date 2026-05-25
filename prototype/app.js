// Wire up screens, navigation, theme toggle.

(function () {
  const mount = document.getElementById('screen-mount');
  const jump = document.getElementById('screen-jump');
  const list = document.getElementById('screen-list');
  const themeBtn = document.getElementById('theme-toggle');

  // Populate sidebar list (grouped) + dropdown
  let lastGroup = null;
  screenOrder.forEach((s, i) => {
    if (s.group && s.group !== lastGroup) {
      const h = document.createElement('div');
      h.className = 'group-header';
      h.textContent = s.group;
      list.appendChild(h);
      lastGroup = s.group;
    }
    const li = document.createElement('li');
    li.dataset.key = s.key;
    li.innerHTML = `<span>${s.label}</span>`;
    li.addEventListener('click', () => render(s.key));
    list.appendChild(li);

    const opt = document.createElement('option');
    opt.value = s.key;
    opt.textContent = `${(i + 1)}. ${s.label.replace(/^↳\s*/, '')}`;
    jump.appendChild(opt);
  });
  jump.addEventListener('change', e => render(e.target.value));

  function render(key) {
    if (!Screens[key]) {
      console.warn('No screen', key);
      return;
    }
    mount.innerHTML = Screens[key]();
    // Mark active in sidebar + dropdown
    Array.from(list.children).forEach(li => {
      if (li.dataset && li.dataset.key !== undefined) {
        li.classList.toggle('active', li.dataset.key === key);
      }
    });
    jump.value = key;
    // Wire data-nav buttons inside this screen
    mount.querySelectorAll('[data-nav]').forEach(el => {
      el.addEventListener('click', e => {
        e.stopPropagation();
        render(el.dataset.nav);
      });
    });
    // Scroll mount to top
    const scroll = mount.querySelector('.scroll');
    if (scroll) scroll.scrollTop = 0;
  }

  // Theme toggle
  themeBtn.addEventListener('click', () => {
    const cur = document.body.dataset.theme;
    document.body.dataset.theme = cur === 'light' ? 'dark' : 'light';
  });

  // Boot
  render('welcome');
})();
