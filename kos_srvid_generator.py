#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
oscam.srvid generator - parses https://en.kingofsat.net/pack-<slug>

Output line format (same as the old s3n0 / persianpros script):
    CAID[,CAID...]:SID|PACKAGE|Channel name
Free-to-air channels get CAID 0000.

Usage examples:
    pip install requests beautifulsoup4
    python3 kos_srvid_generator.py                       # uses the PACKAGES block inside this script
    python3 kos_srvid_generator.py --packs-file packages.txt   # optional external list
    python3 kos_srvid_generator.py --from-file oscam.srvid   # only the packages in your old file
    python3 kos_srvid_generator.py --packs skydigital ncplus canal
    python3 kos_srvid_generator.py --debug skydigital    # print parsed rows of one package, no file written
"""

import argparse
import datetime
import re
import sys
import time

import requests
from bs4 import BeautifulSoup

BASE = "https://en.kingofsat.net"
HEADERS = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) srvid-generator"}
HEX4 = re.compile(r"\b[0-9A-F]{4}\b")

# Only used when the encryption cell shows a system name but no CAID code at all.
# These are generic fallbacks (first CAID of the family) - check the report at the end.
FALLBACK_CAID = {
    "videoguard": "0963", "nds": "0963", "conax": "0B00", "viaccess": "0500",
    "irdeto": "0600", "nagravision": "1800", "nagra": "1800", "seca": "0100",
    "mediaguard": "0100", "cryptoworks": "0D00", "betacrypt": "1702",
    "biss": "2600", "dre": "4AE0", "powervu": "0E00", "verimatrix": "5581",
    "tandberg": "1010", "streamguard": "4AEE",
}

fallback_used = []

# ---------------------------------------------------------------------------
# PACKAGES - one per line:  slug   CAIDs-for-encrypted-channels   # name
# * To skip a package put '#' at the start of its line.
# * CAIDs were taken from the old oscam.srvid (2024-05-07). Free channels always get 0000.
# * '-' = no CAID in the old file: the script tries to read it from the site, then
#   falls back to a generic CAID of the encryption system (see the warning at the end).
# ---------------------------------------------------------------------------
PACKAGES = """
a1bg              0B00                                       # A1 Bulgaria (Bulgaria, 258)
add               0604                                       # ADD (UAE, 2)
akta              0500,0B00                                  # Akta (Romania, 1)
alemtv            -                                          # Älem TV (Turkmenistan, 192)
allente           -                                          # Allente (Sweden, 378)
antiksat          0B00                                         Antik Sat (Slovakia, 19)
anuvu             -                                          # Anuvu (USA, 117)
arddigital        FFFE                                       # ARD Digital (Germany, 100)
austriasat        0D05                                       # Austriasat (Austria, 94)
austriasatmagyar  0D05                                       # AustriaSat Magyarorszag (Hungary, 4)
azamdigital       -                                          # Azam Digital (Tanzania, 55)
bbc               -                                          # BBC (UK, 4)
bfbs              -                                          # BFBS (UK, 118)
bis               0500,0100                                  # Bis (France, 109)
boobles           -                                          # Boobles (Germany, 29)
bulsatcom         -                                          # Bulsatcom (Bulgaria, 136)
canaldigitaal     0100,0622                                  # Canal Digitaal (Netherlands, 83)
canalpluscz       -                                          # Canal+ Czechia & Slovakia (Slovakia, 167)
canal             -                                          # Canal+ France (France, 188)
cosmote           -                                          # Cosmote (Greece, 116)
dsmart            092B                                       # D-Smart (Turkey, 94)
digitv            1802,1880                                  # Digi TV (Romania, 172)
digitalb          0B00                                       # Digit Alb (Albania, 104)
digiturk          0D00,0664                                  # Digiturk (Turkey, 113)
directone         -                                          # Direct One (Hungary, 137)
direct2home       -                                          # Direct2Home (Austria, 3)
focussat          0B02                                       # Focus Sat (Romania, 347)
fransat           0500                                       # Fransat (France, 60)
freesat           -                                          # Freesat (UK, 9)
hdplus            1830                                       # HD+ (Germany, 52)
home3             -                                          # Home 3 (Latvia, 47)
kabelkiosk        0B00,09AF                                  # Kabelkiosk (Germany, 29)
msattv            -                                          # M:Sat TV (Serbia, 281)
maxtv             0500                                       # Max TV (Croatia, 77)
mediaset          1803                                       # Mediaset (Italy, 70)
meo               0100,1814                                  # Meo (Portugal, 128)
digitalplusa      0100,1810                                  # Movistar+ (Spain, 161)
mtv               0B00,0D00                                  # MTV Networks (UK, 12)
mcafrica          1800                                       # Multichoice Africa (South Africa, 41)
neosat            5581,4AEE,0B00                             # Neosat (Bulgaria, 185)
nos               1802                                       # Nos (Portugal, 255)
nova              0604                                       # Nova (Greece, 116)
ntvrussia         -                                          # NTV+ Vostok (Russia, 97)
orange            0500                                       # Orange (France, 1)
orangepl          0500                                       # Orange Polska (Poland, 225)
orangeromania     0500                                       # Orange Romania (Romania, 149)
orangesk          0500                                       # OrangeSat Slovakia (Slovakia, 13)
showtime          -                                          # Orbit Showtime Network (UAE, 21)
orfdigital        0D05,0D95                                  # ORF Digital (Austria, 32)
pink              091F                                       # Pink International (Serbia, 49)
ncplus            0100,0B01                                  # Platforma Canal+ (Poland, 283)
polsat            1803,1861                                  # Polsat Box (Poland, 290)
rai               0100,183D,183E,1856                        # RAI (Italy, 164)
skygermany        1833,1834,1702,1722,09C4,09AF,098D         # Sky Deutschland (Germany, 158)
skydigital        0963                                       # Sky Digital (UK, 562)
skyitalia         0919,093B,09CD                             # Sky Italia (Italy, 148)
ssr               0500                                       # SSR/SRG (Switzerland, 4)
teammedia         -                                          # Team:Media (Bosnia, 27)
telesat           0100                                       # TeleSat (Belgium, 49)
telly             -                                          # Telly (France, 213)
tivibu            -                                          # Tivibu (Turkey, 72)
tivusat           183D,183E,1856                             # TivuSat (Italy, 67)
tntsat            0500                                       # TNTSAT (France, 49)
totaltv           091F                                       # Total TV (Serbia, 373)
tring             0BAA                                       # Tring Digital (Albania, 69)
tvvlaanderen      0100,0500                                  # TV Vlaanderen (Belgium, 73)
viasat            090F,093E                                  # Viasat (Sweden, 48)
viasatua          090F,093E                                  # Viasat Ukraine (Ukraine, 7)
visat             -                                          # Visat (Mexico, 6)
vivacom           09BD                                       # Vivacom (Bulgaria, 149)
volnatelka        0668,069A                                  # Volna Telka (Czech Republic, 4)
zdfvision         FFFE                                       # ZDF Vision (Germany, 9)
"""


def get(url, retries=3):
    for i in range(retries):
        try:
            r = requests.get(url, headers=HEADERS, timeout=30)
            if r.status_code == 200:
                return r.text
            print(f"  HTTP {r.status_code} for {url}", file=sys.stderr)
        except requests.RequestException as e:
            print(f"  error {e} ({url})", file=sys.stderr)
        time.sleep(2 * (i + 1))
    return None


def discover_packs():
    """Collect every pack-<slug> link from the /packages page."""
    html = get(f"{BASE}/packages")
    if not html:
        return []
    soup = BeautifulSoup(html, "html.parser")
    slugs = []
    for a in soup.find_all("a", href=True):
        m = re.search(r"/pack-([A-Za-z0-9_\-]+)(?:\.php)?$", a["href"])
        if m and m.group(1) not in slugs:
            slugs.append(m.group(1))
    return slugs


def packs_from_block(text):
    """Parse the embedded PACKAGES block -> ordered list of (slug, caid or None)."""
    out = []
    for line in text.splitlines():
        parts = line.split("#", 1)[0].split()
        if not parts:
            continue
        out.append((parts[0], parts[1] if len(parts) > 1 and parts[1] != "-" else None))
    return out


def packs_from_txt(path):
    """One slug per line; anything after '#' is a comment, '#slug' disables the package."""
    packs = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            slug = line.split("#", 1)[0].strip().split()
            if slug and slug[0] not in packs:
                packs.append(slug[0])
    return packs


def packs_from_old_file(path):
    seen = []
    with open(path, encoding="utf-8", errors="ignore") as f:
        for line in f:
            if line.startswith("#") or "|" not in line:
                continue
            p = line.split("|")[1].strip().lower()
            if p and p not in seen:
                seen.append(p)
    return seen


def caids_from_cell(cell):
    """Extract CAIDs from the encryption cell (text + title/alt attributes)."""
    text = cell.get_text(" ", strip=True)
    if not text or text.lower().startswith("clear"):
        return ["0000"], False
    blob = [text]
    for tag in cell.find_all(True):
        for attr in ("title", "alt"):
            if tag.get(attr):
                blob.append(tag[attr])
    blob = " ".join(blob).upper()
    caids = []
    for c in HEX4.findall(blob):
        if c not in caids:
            caids.append(c)
    if caids:
        return caids, False
    low = text.lower()
    for key, caid in FALLBACK_CAID.items():
        if key in low:
            return [caid], True
    return [], True


def parse_pack(slug, default_caid=None):
    html = get(f"{BASE}/pack-{slug}")
    if not html:
        return None
    soup = BeautifulSoup(html, "html.parser")
    out = []
    for tr in soup.find_all("tr"):
        tds = tr.find_all("td", recursive=False)
        if len(tds) < 8:
            continue
        # index of the "Packages" cell = the one holding links to pack-xxx
        pk = next((i for i, td in enumerate(tds)
                   if td.find("a", href=re.compile(r"pack-"))), None)
        if pk is None or pk < 3 or pk + 2 >= len(tds):
            continue
        sid_txt = tds[pk + 2].get_text(strip=True)
        if not sid_txt.isdigit():
            continue
        name_cell = tds[pk - 3]
        a = name_cell.find("a")
        name = (a.get_text(" ", strip=True) if a else name_cell.get_text(" ", strip=True))
        name = re.sub(r"\s+", " ", name).strip()
        if not name:
            continue
        caids, fb = caids_from_cell(tds[pk + 1])
        if default_caid and caids != ["0000"]:      # encrypted -> CAIDs from the old file
            caids, fb = default_caid.split(","), False
        if not caids:
            continue
        if fb:
            fallback_used.append((slug, name))
        out.append((",".join(caids), format(int(sid_txt), "04X"), name))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--packs", nargs="*", help="package slugs, e.g. skydigital ncplus")
    ap.add_argument("--packs-file", help="text file with package slugs (default: packages.txt if it exists)")
    ap.add_argument("--from-file", help="read package list from an existing oscam.srvid")
    ap.add_argument("--debug", metavar="SLUG", help="print parsed rows of one package and exit")
    ap.add_argument("-o", "--output", default="oscam.srvid")
    ap.add_argument("--delay", type=float, default=1.0, help="seconds between requests")
    args = ap.parse_args()

    if args.debug:
        for row in (parse_pack(args.debug) or [])[:40]:
            print(row)
        return

    if args.packs:
        packs = [(p, None) for p in args.packs]
    elif args.packs_file:
        packs = [(p, None) for p in packs_from_txt(args.packs_file)]
    elif args.from_file:
        packs = [(p, None) for p in packs_from_old_file(args.from_file)]
    else:
        packs = packs_from_block(PACKAGES)
    if not packs:
        sys.exit("No packages to process.")

    lines, failed = [], []
    for n, (slug, caid) in enumerate(packs, 1):
        print(f"[{n}/{len(packs)}] {slug}")
        rows = parse_pack(slug, caid)
        if rows is None:
            failed.append(slug)
            continue
        seen = set()
        for caid, sid, name in rows:
            key = (caid, sid, name)
            if key in seen:
                continue
            seen.add(key)
            lines.append(f"{caid}:{sid}|{slug.upper()}|{name}")
        print(f"    {len(seen)} entries")
        time.sleep(args.delay)

    with open(args.output, "w", encoding="utf-8") as f:
        f.write("\n#################################################################################\n")
        f.write("### oscam.srvid generated from http://en.KingOfSat.net/pack-<name>\n")
        f.write("### based on the script by s3n0 / persianpros, rewritten for the current site layout\n")
        f.write("#################################################################################\n\n")
        f.write(f"### File creation date: {datetime.date.today()}\n\n")
        f.write("\n".join(lines) + "\n")

    print(f"\nDone: {len(lines)} lines -> {args.output}")
    if failed:
        print("Failed packages (slug probably different on the site):", ", ".join(failed))
    if fallback_used:
        print(f"WARNING: {len(fallback_used)} channels had no CAID code on the page; "
              "a generic CAID was used. Example:", fallback_used[:3])


if __name__ == "__main__":
    main()
