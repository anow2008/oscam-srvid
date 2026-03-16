#!/bin/bash

HEADER="
#################################################################################
### - generator of the 'oscam.srvid' file
### - updated for 2026 HTML structure
#################################################################################
"

create_srvid_file()
{
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    
    echo "Fetching: ${1^^} ..."
    
    # تحميل الصفحة مع محاكاة كاملة للمتصفح
    wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL"

    if [ -s /tmp/kos.html ]; then
        # منطق جديد تماماً: 
        # 1. البحث عن الروابط التي تحتوي على كلمة 'pos' (لأنها تحتوي على الـ SID دائماً في KingOfSat)
        # 2. استخراج الاسم الذي يليه
        grep -oP 'pos=[0-9]+|class="A3">[^<]+' /tmp/kos.html | sed 's/pos=//; s/class="A3">//' > /tmp/raw_data.txt
        
        # معالجة البيانات: كل سطرين يمثلان (SID ثم اسم) أو العكس
        awk -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            {
                if ($1 ~ /^[0-9]+$/) {
                    sid = $1;
                    if (chname != "") {
                        printf "%s:%04X|%s|%s\n", CAIDS, sid, PROVIDER, chname;
                        chname = "";
                    }
                } else {
                    chname = $0;
                }
            }' /tmp/raw_data.txt > "/tmp/oscam__${1,,}.srvid"

        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo "Success: $(wc -l < /tmp/oscam__${1,,}.srvid) channels found."
        else
            echo "Failed: No channels found. Site might be blocking script-based access."
        fi
        rm -f /tmp/kos.html /tmp/raw_data.txt
    else
        echo "Error: Download failed or empty file."
    fi
}

echo "$HEADER"
OSCAM_SRVID="oscam.srvid"
echo "$HEADER" > $OSCAM_SRVID
echo -e "### Updated: $(date)\n" >> $OSCAM_SRVID

# جرب باقتين فقط للتأكد
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"

cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

echo "Final file: $OSCAM_SRVID"
