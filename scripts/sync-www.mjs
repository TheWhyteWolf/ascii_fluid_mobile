// Sync the source web app (root) into www/ — the Capacitor webDir.
// Keeps the root index.html as the single source of truth (GitHub Pages stays live)
// while giving Capacitor a clean asset dir with no node_modules / android / scripts.
import { cpSync, rmSync, mkdirSync, existsSync } from 'node:fs';

rmSync('www', { recursive: true, force: true });
mkdirSync('www', { recursive: true });

cpSync('index.html', 'www/index.html');
cpSync('fonts', 'www/fonts', { recursive: true });
for (const extra of ['manifest.webmanifest', 'icon.svg', 'sw.js']) {
  if (existsSync(extra)) cpSync(extra, 'www/' + extra);
}
if (existsSync('assets')) cpSync('assets', 'www/assets', { recursive: true });

console.log('synced -> www/');
