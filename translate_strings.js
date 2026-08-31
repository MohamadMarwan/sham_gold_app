const fs = require('fs');
const path = require('path');

const ARABIC_REGEX = /[\u0600-\u06FF]/;

async function translateText(text, targetLang) {
    try {
        const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=ar&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
        const response = await fetch(url);
        const data = await response.json();
        return data[0].map(s => s[0]).join('');
    } catch (e) {
        console.error(`Error translating "${text}":`, e.message);
        return text; 
    }
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function processFile(filePath, targetLang) {
    console.log(`Processing ${filePath} for target ${targetLang}...`);
    const content = fs.readFileSync(filePath, 'utf8');
    const json = JSON.parse(content);
    
    let updatedCount = 0;
    for (const key of Object.keys(json)) {
        const val = json[key];
        if (typeof val === 'string' && ARABIC_REGEX.test(val)) {
            const translated = await translateText(val, targetLang);
            if (translated !== val) {
                json[key] = translated;
                updatedCount++;
            }
            await sleep(150);
        }
    }
    
    if (updatedCount > 0) {
        fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
        console.log(`Updated ${updatedCount} keys in ${filePath}`);
    } else {
        console.log(`No Arabic text found in ${filePath} to translate.`);
    }
}

async function main() {
    const enFile = path.join(__dirname, 'assets', 'translations', 'en.json');
    const trFile = path.join(__dirname, 'assets', 'translations', 'tr.json');
    
    await processFile(enFile, 'en');
    await processFile(trFile, 'tr');
    
    console.log('Translation process complete.');
}

main().catch(console.error);
