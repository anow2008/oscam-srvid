#!/bin/bash

HEADER="
#################################################################################
### - updated script for oscam.srvid generation (FIXED 2026)
#################################################################################
"

create_srvid_file()
{
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    
    echo "Downloading Package: ${1^^} ..."
    
    # تحميل الصفحة مع محاكاة كاملة
    wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL"

    if [ -s /tmp/kos.html ]; then
        # استخراج البيانات باستخدام منطق أكثر مرونة
        # نبحث عن الأسطر التي تحتوي على SID (رقم) واسم القناة (نص بين الـ Tags)
        perl -lne 'print $1 if /class="s">(\d+)</; print $1 if /class="A3">([^<]+)</' /tmp/kos.html > /tmp/raw_data.txt
        
        awk -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            {
                if ($0 ~ /^[0-9]+$/) {
                    sid = $0;
                    if (chname != "") {
                        printf "%s:%04X|%s|%s\n", CAIDS, sid, PROVIDER, chname;
                        chname = "";
                    }
                } else {
                    chname = $0;
                }
            }' /tmp/raw_data.txt > "/tmp/oscam__${1,,}.srvid"

        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo "Successfully found $(wc -l < /tmp/oscam__${1,,}.srvid) channels."
        else
            echo "Warning: No data found for ${1}. Structure might be protected."
        fi
        rm -f /tmp/kos.html /tmp/raw_data.txt
    else
        echo "Error: Could not download page."
    fi
    # انتظار بسيط لتجنب الحظر
    sleep 2
}

echo "$HEADER"
OSCAM_SRVID="oscam.srvid"
echo "$HEADER" > $OSCAM_SRVID
echo -e "### Created: $(date)\n" >> $OSCAM_SRVID

# جرب باقة واحدة للتأكد
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"

cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

echo "Final status: $(grep -c "|" $OSCAM_SRVID) channels added to $OSCAM_SRVID"
