#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
oscam.srvid generator - parses https://en.kingofsat.net/pack-<slug>

Output line format (same as the old s3n0 / persianpros script):
    CAID[,CAID...]:SID|PACKAGE|Channel name
Free-to-air channels get CAID 0000.

Usage examples:
    pip install requests beautifulsoup4
    python3 kos_srvid_generator.py                       # uses packages.txt if present, else all packages on /packages
    python3 kos_srvid_generator.py --packs-file packages.txt
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


def parse_pack(slug):
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

    import os
    if args.packs:
        packs = args.packs
    elif args.packs_file or (not args.from_file and os.path.exists("packages.txt")):
        packs = packs_from_txt(args.packs_file or "packages.txt")
    elif args.from_file:
        packs = packs_from_old_file(args.from_file)
    else:
        packs = discover_packs()
    if not packs:
        sys.exit("No packages to process.")

    lines, failed = [], []
    for slug in packs:
        print(f"[{packs.index(slug)+1}/{len(packs)}] {slug}")
        rows = parse_pack(slug)
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
