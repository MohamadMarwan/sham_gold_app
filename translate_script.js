const fs = require('fs');
const path = require('path');

// Note: In CommonJS context, we can dynamically import an ES module
async function run() {
    const { translate } = await import('@vitalets/google-translate-api');
    
    const ARABIC_REGEX = /[\u0600-\u06FF]/;
    
    const sleep = ms => new Promise(r => setTimeout(r, ms));
    
    async function translateFile(filePath, targetLang) {
        console.log(`Translating ${filePath} to ${targetLang}...`);
        const content = fs.readFileSync(filePath, 'utf8');
        const json = JSON.parse(content);
        
        let updatedCount = 0;
        for (const key of Object.keys(json)) {
            const val = json[key];
            if (typeof val === 'string' && ARABIC_REGEX.test(val)) {
                if (val.length > 200 && val.includes('loadInterstitialAd')) {
                    continue;
                }
                
                try {
                    const { text } = await translate(val, { to: targetLang });
                    if (text && text !== val) {
                        console.log(`[${key}] ${val.substring(0, 30)} -> ${text.substring(0, 30)}`);
                        json[key] = text;
                        updatedCount++;
                    }
                    await sleep(300); // polite delay
                } catch (e) {
                    console.error(`Failed to translate ${key}: ${e.message}`);
                    await sleep(1000);
                }
            }
        }
        
        if (updatedCount > 0) {
            fs.writeFileSync(filePath, JSON.stringify(json, null, 2), 'utf8');
            console.log(`Success! Updated ${updatedCount} keys in ${filePath}`);
        } else {
            console.log(`No translation needed for ${filePath}`);
        }
    }
    
    const enFile = path.join(__dirname, 'assets', 'translations', 'en.json');
    const trFile = path.join(__dirname, 'assets', 'translations', 'tr.json');
    
    await translateFile(enFile, 'en');
    await translateFile(trFile, 'tr');
}

run().catch(console.error);
