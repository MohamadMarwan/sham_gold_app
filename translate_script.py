import json
import os
import re
import time
import sys
from deep_translator import GoogleTranslator

# Fix Windows console printing issues
sys.stdout.reconfigure(encoding='utf-8')

ARABIC_REGEX = re.compile(r'[\u0600-\u06FF]')

def is_arabic(text):
    return bool(ARABIC_REGEX.search(str(text)))

def translate_file(file_path, target_lang):
    print(f"Translating {file_path} to {target_lang}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    translator = GoogleTranslator(source='ar', target=target_lang)
    
    updated_count = 0
    for key, value in data.items():
        if isinstance(value, str) and is_arabic(value):
            if len(value) > 200 and 'loadInterstitialAd' in value:
                continue
                
            try:
                translated = translator.translate(value)
                if translated and translated != value:
                    print(f"Translated [{key}]")
                    data[key] = translated
                    updated_count += 1
                    time.sleep(0.1)
            except Exception as e:
                # Ignore failures on specific huge strings or weird chars
                print(f"Skipping {key} due to error.")
                time.sleep(0.5)
                
    if updated_count > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Success! Updated {updated_count} keys in {file_path}")
    else:
        print(f"No translation needed for {file_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    en_file = os.path.join(base_dir, 'assets', 'translations', 'en.json')
    tr_file = os.path.join(base_dir, 'assets', 'translations', 'tr.json')
    
    translate_file(en_file, 'en')
    translate_file(tr_file, 'tr')
