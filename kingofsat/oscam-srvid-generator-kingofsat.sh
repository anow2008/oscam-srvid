#!/bin/bash

HEADER="
#################################################################################
### - the script serves as a generator of the 'oscam.srvid' file
### - based on data parsing from website: http://en.KingOfSat.net/pack-XXXXXX.php
### - script updated for 2026 compatibility
#################################################################################
"

#################################################################################

create_srvid_file()
{
    # $1 = اسم الباقة، $2 = الـ CAID
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    # تغيير المتصفح ليكون أكثر واقعية
    UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    
    echo "Processing Package: ${1^^} ..."
    
    # إضافة وقت انتظار عشوائي (بين 2 إلى 4 ثواني) لتجنب حظر الموقع
    sleep $((2 + RANDOM % 3))

    if wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL"; then
        
        # استخراج البيانات: نبحث عن الـ SID والاسم بناءً على الكود المصدري الجديد
        # تم دمج grep و sed بشكل أكثر دقة
        grep -E 'class="A3"|class="s"' /tmp/kos.html | sed 's/<[^>]*>//g' | sed 's/^[ \t]*//;s/[ \t]*$//' > /tmp/clean_data.txt
        
        awk -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            BEGIN { chname = "" }
            {
                # إذا كان السطر أرقام فقط (SID) والاسم مسجل مسبقاً
                if ($0 ~ /^[0-9]+$/ && chname != "") {
                    printf "%s:%04X|%s|%s\n", CAIDS, $0, PROVIDER, chname;
                    chname = ""; 
                } else if ($0 != "" && $0 !~ /^[0-9]+$/) {
                    # إذا كان نصاً فهو اسم القناة
                    chname = $0;
                }
            }' /tmp/clean_data.txt > "/tmp/oscam__${1,,}.srvid"
        
        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo "Successfully created: /tmp/oscam__${1,,}.srvid"
        else
            echo "Warning: No data found for ${1}. Site might be throttling requests."
        fi
        rm -f /tmp/kos.html /tmp/clean_data.txt
    else
        echo "URL download failed !!! URL: ${URL}"
    fi
}

#################################################################################

echo "$HEADER"
OSCAM_SRVID="oscam.srvid"

# تصفير الملف النهائي قبل البدء
echo "$HEADER" > $OSCAM_SRVID
echo -e "### File creation date: $(date '+%Y-%m-%d')\n" >> $OSCAM_SRVID

### إنشاء الملفات المؤقتة للباقات:
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"
create_srvid_file "skygermany" "098C,09C4,098D"
create_srvid_file "skyitalia" "0919,093B,09CD"
create_srvid_file "skylink" "0D96,0624"
create_srvid_file "tivusat" "183D,183E,1856"

### تجميع النتائج:
cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

if [ -f "$OSCAM_SRVID" ]; then
    echo "--------------------------------------------------"
    echo "All merged into: ${OSCAM_SRVID}"
    echo "Total channels found: $(grep -c "|" $OSCAM_SRVID)"
fi
