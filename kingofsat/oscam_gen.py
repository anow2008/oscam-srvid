import requests
import re
import os
from datetime import datetime

def create_srvid_data(package, caids):
    url = f"https://en.kingofsat.net/pack-{package.lower()}.php"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': 'https://en.kingofsat.net/'
    }
    
    print(f"Fetching: {package.upper()}...")
    try:
        # تعطيل verify=False لتجنب مشاكل شهادات SSL القديمة في بعض البيئات
        response = requests.get(url, headers=headers, timeout=20, verify=False)
        if response.status_code == 200:
            # البحث عن الـ SID والأسماء في كود الموقع
            sids = re.findall(r'class="s">(\d+)<', response.text)
            names = re.findall(r'class="A3">([^<]+)<', response.text)
            
            lines = []
            for i in range(min(len(sids), len(names))):
                sid_hex = "{:04X}".format(int(sids[i]))
                lines.append(f"{caids}:{sid_hex}|{package.upper()}|{names[i].strip()}")
            return lines
        return []
    except Exception as e:
        print(f"Error {package}: {e}")
        return []

# قائمة الباقات (نفس التي كانت في ملفك الأصلي)
packages = [
    ("bein", "0500"), ("osn", "0604"), ("art", "0604"), ("skygermany", "1833,1834,1702,1722,09C4,09AF,098D"),
    ("skyitalia", "0919,093B,09CD"), ("tivusat", "183D,183E,1856"), ("skylink", "0D03,0D70,0D96,0624"),
    ("digiturk", "0D00,0664"), ("canal", "0000"), ("bis", "0500,0100"), ("polsat", "1803,1861")
]

header = f"""#################################################################################
### - OSCam SRVID Generator (Python Version)
### - Generated on: {datetime.now().strftime('%Y-%m-%d')}
#################################################################################\n\n"""

all_entries = []
for pkg, caid in packages:
    all_entries.extend(create_srvid_data(pkg, caid))

if all_entries:
    with open("oscam.srvid", "w", encoding="utf-8") as f:
        f.write(header + "\n".join(all_entries))
    print(f"Successfully generated oscam.srvid with {len(all_entries)} channels.")
else:
    print("Failed to generate any data.")
