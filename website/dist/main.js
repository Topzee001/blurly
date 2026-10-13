const menuButton = document.querySelector('.nav-toggle');
const menu = document.querySelector('.nav-links');

menuButton?.addEventListener('click', () => {
  const isOpen = menuButton.getAttribute('aria-expanded') === 'true';
  menuButton.setAttribute('aria-expanded', String(!isOpen));
  menuButton.setAttribute('aria-label', isOpen ? 'Open menu' : 'Close menu');
  menu.classList.toggle('is-open', !isOpen);
});

menu?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => {
    menuButton.setAttribute('aria-expanded', 'false');
    menuButton.setAttribute('aria-label', 'Open menu');
    menu.classList.remove('is-open');
  });
});

const comparison = document.querySelector('.comparison');
const comparisonRange = document.querySelector('.comparison-range');

comparisonRange?.addEventListener('input', () => {
  comparison.style.setProperty('--split', `${comparisonRange.value}%`);
});
