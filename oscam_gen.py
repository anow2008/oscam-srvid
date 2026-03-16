import requests
import re
import os
from datetime import datetime

def fetch_srvid(package, caids):
    url = f"https://en.kingofsat.net/pack-{package.lower()}.php"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9'
    }
    
    print(f"-> Processing: {package.upper()}")
    try:
        # استخدام timeout أطول لضمان التحميل من سيرفرات جيت هاب
        response = requests.get(url, headers=headers, timeout=30, verify=False)
        if response.status_code == 200:
            # استخراج SID (class="s") والأسماء (class="A3")
            sids = re.findall(r'class="s">(\d+)<', response.text)
            names = re.findall(r'class="A3">([^<]+)<', response.text)
            
            output = []
            for i in range(min(len(sids), len(names))):
                sid_hex = "{:04X}".format(int(sids[i]))
                output.append(f"{caids}:{sid_hex}|{package.upper()}|{names[i].strip()}")
            return output
        else:
            print(f"!! Failed {package} (Status {response.status_code})")
            return []
    except Exception as e:
        print(f"!! Error {package}: {e}")
        return []

# قائمة الباقات الكاملة من ملفك الأصلي
packages = [
    ("bein", "0500"), ("osn", "0604"), ("art", "0604"), ("add", "0604"),
    ("skygermany", "1833,1834,1702,1722,09C4,09AF,098D"),
    ("skyitalia", "0919,093B,09CD"), ("tivusat", "183D,183E,1856"),
    ("skylink", "0D03,0D70,0D96,0624"), ("polsat", "1803,1861"),
    ("digiturk", "0D00,0664"), ("canal", "0000"), ("bis", "0500,0100")
]

final_data = []
header = f"#################################################################################\n"
header += f"### - OSCam SRVID Generator (Python Version)\n"
header += f"### - Generated on: {datetime.now().strftime('%Y-%m-%d')}\n"
header += f"#################################################################################\n\n"

for pkg, caid in packages:
    res = fetch_srvid(pkg, caid)
    if res:
        final_data.extend(res)

# حفظ الملف فقط إذا وجدت بيانات لضمان عدم حدوث خطأ في جيت هاب
if final_data:
    with open("oscam.srvid", "w", encoding="utf-8") as f:
        f.write(header + "\n".join(final_data))
    print(f"DONE: Successfully created oscam.srvid with {len(final_data)} channels.")
else:
    # إنشاء ملف فارغ مؤقتاً لتجنب خطأ الـ Git
    with open("oscam.srvid", "w") as f:
        f.write(header + "# No data found in this run.")
    print("WARNING: No channels found, created empty file to prevent Git error.")
