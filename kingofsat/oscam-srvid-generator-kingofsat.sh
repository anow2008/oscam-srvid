import requests
import re
import os
from datetime import datetime

def create_srvid_file(package, caids):
    url = f"https://en.kingofsat.net/pack-{package.lower()}.php"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': 'https://en.kingofsat.net/'
    }
    
    print(f"Fetching Package: {package.upper()}...")
    try:
        response = requests.get(url, headers=headers, timeout=15, verify=False)
        if response.status_code == 200:
            # استخراج SID واسم القناة باستخدام Regex
            # البحث عن class="s" للـ SID و class="A3" لاسم القناة
            sids = re.findall(r'class="s">(\d+)<', response.text)
            names = re.findall(r'class="A3">([^<]+)<', response.text)
            
            if not sids or not names:
                print(f"No data found for {package}")
                return ""

            results = []
            # دمج الـ SIDs مع الأسماء (KingOfSat يضعهم بترتيب متوازي)
            for i in range(min(len(sids), len(names))):
                sid_hex = "{:04X}".format(int(sids[i]))
                results.append(f"{caids}:{sid_hex}|{package.upper()}|{names[i].strip()}")
            
            return "\n".join(results) + "\n"
        else:
            print(f"Failed to download {package}. Status: {response.status_code}")
            return ""
    except Exception as e:
        print(f"Error processing {package}: {e}")
        return ""

# الإعدادات
packages = [
    ("bein", "0500"),
    ("osn", "0604"),
    ("art", "0604"),
    ("skygermany", "098C,09C4,098D"),
    ("skyitalia", "0919,093B,09CD"),
    ("tivusat", "183D,183E,1856")
]

header_text = f"""#################################################################################
### - OSCam SRVID Generator (Python Version)
### - Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
#################################################################################\n\n"""

final_content = header_text
for pkg, caid in packages:
    final_content += create_srvid_file(pkg, caid)

# حفظ الملف النهائي
with open("oscam.srvid", "w", encoding="utf-8") as f:
    f.write(final_content)

print(f"\nDone! Final file saved as oscam.srvid")
