// Réglages Android après "cap add android" : écran en hauteur, plein écran et vibration autorisée.
import { readFileSync, writeFileSync } from 'node:fs';

const file = 'android/app/src/main/AndroidManifest.xml';
let xml = readFileSync(file, 'utf8');
if (!xml.includes('android:screenOrientation')) xml = xml.replace('<activity', '<activity android:screenOrientation="portrait"');
if (!xml.includes('android.permission.VIBRATE')) xml = xml.replace('</manifest>', '    <uses-permission android:name="android.permission.VIBRATE" />\n</manifest>');
writeFileSync(file, xml);
console.log('AndroidManifest.xml mis à jour');
