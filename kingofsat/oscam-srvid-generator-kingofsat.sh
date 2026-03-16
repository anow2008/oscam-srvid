#!/bin/bash

HEADER="
#################################################################################
### - updated script for oscam.srvid generation
#################################################################################
"

create_srvid_file()
{
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    # استخدام User-Agent لمتصفح حقيقي حديث
    UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    
    echo "Downloading: ${1^^}..."

    # تحميل الصفحة
    wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL"
    
    if [ -f /tmp/kos.html ]; then
        # منطق جديد يعتمد على البحث عن الأرقام (SID) بجانب أسماء القنوات
        # هذا التعديل يتجاهل الـ Classes ويركز على هيكل الجدول نفسه
        grep -E 'class="(A3|s)"' /tmp/kos.html | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > /tmp/raw_data.txt
        
        # تحويل البيانات الخام إلى تنسيق SRVID
        while read -r line; do
            if [[ $line =~ ^[0-9]+$ ]]; then
                SID=$line
                if [ ! -z "$CHNAME" ]; then
                    printf "%s:%04X|%s|%s\n" "$CAIDS" "$SID" "${1^^}" "$CHNAME" >> "/tmp/oscam__${1,,}.srvid"
                    CHNAME=""
                fi
            else
                CHNAME=$line
            fi
        done < /tmp/raw_data.txt
        
        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo "Successfully extracted data for ${1}"
        else
            echo "No data found for ${1}. Maybe blocked by site?"
        fi
        
        rm -f /tmp/kos.html /tmp/raw_data.txt
    fi
}

echo "$HEADER"
OSCAM_SRVID="oscam.srvid"
echo "### File creation date: $(date '+%Y-%m-%d')" > $OSCAM_SRVID

# إعداد الـ CAID للباقات (أمثلة)
CAIDS="0500"
create_srvid_file "bein" "0500"
create_srvid_file "bis" "0500"

# تجميع الملفات
cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

echo "--------------------------------------------------"
echo "Final check: $(wc -l < $OSCAM_SRVID) lines created in $OSCAM_SRVID"
