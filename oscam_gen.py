import requests
import re
from datetime import datetime
import urllib3

# تعطيل تحذيرات SSL
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def create_srvid_data(package, caids):
    url = f"https://en.kingofsat.net/pack-{package.lower()}.php"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Referer': 'https://en.kingofsat.net/'
    }
    
    print(f"Fetching: {package.upper()}...")
    try:
        response = requests.get(url, headers=headers, timeout=20, verify=False)
        if response.status_code == 200:
            # البحث عن SID والأسماء في كود الموقع
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

# القائمة الكاملة للباقات من ملفك الأصلي
packages = [
    ("bein", "0500"), ("osn", "0604"), ("art", "0604"), 
    ("skygermany", "1833,1834,1702,1722,09C4,09AF,098D"),
    ("skyitalia", "0919,093B,09CD"), ("tivusat", "183D,183E,1856"), 
    ("skylink", "0D03,0D70,0D96,0624"), ("polsat", "1803,1861"),
    ("rai", "0100,183D,183E,1856"), ("canal", "0000"), ("bis", "0500,0100")
]

header = f"#################################################################################\n"
header += f"### - OSCam SRVID Generator (Python Version)\n"
header += f"### - Generated on: {datetime.now().strftime('%Y-%m-%d')}\n"
header += f"#################################################################################\n\n"

all_entries = []
for pkg, caid in packages:
    res = create_srvid_data(pkg, caid)
    if res:
        all_entries.extend(res)

if all_entries:
    with open("oscam.srvid", "w", encoding="utf-8") as f:
        f.write(header + "\n".join(all_entries))
    print(f"Success! {len(all_entries)} channels saved to oscam.srvid")
else:
    print("Zero channels found. Something is wrong with the site connection.")
