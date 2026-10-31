// Prépare le dossier www de l'application à partir de la page du jeu (web/billes.html) :
// ajoute l'en-tête HTML complet et remplace les bibliothèques chargées depuis internet par des copies locales,
// pour que le jeu démarre même sans connexion.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const www = join(root, 'www');
mkdirSync(join(www, 'lib'), { recursive: true });

let page = readFileSync(join(root, '..', 'web', 'billes.html'), 'utf8');
const libs = [
  ['https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js', 'three/build/three.min.js', 'lib/three.min.js'],
  ['https://cdnjs.cloudflare.com/ajax/libs/cannon.js/0.6.2/cannon.min.js', 'cannon/build/cannon.min.js', 'lib/cannon.min.js']
];
for (const [url, from, to] of libs) {
  if (!page.includes(url)) throw new Error('Bibliothèque introuvable dans la page : ' + url);
  page = page.replace(url, to);
  copyFileSync(join(root, 'node_modules', from), join(www, to));
}

const head = '<!doctype html><html lang="fr"><head><meta charset="utf-8">' +
  '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no">' +
  '<style>:root{color-scheme:light;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)}' +
  'body{margin:0;font:14px system-ui,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style></head><body>';
writeFileSync(join(www, 'index.html'), head + page + '</body></html>');
console.log('www/index.html prêt (' + Math.round(page.length / 1024) + ' Ko)');
