#!/bin/bash

HEADER="
#################################################################################
### - the script serves as a generator of the 'oscam.srvid' file
### - based on data parsing from website: http://en.KingOfSat.net/pack-XXXXXX.php
### - script written by s3n0, 2021-03-02: https://github.com/s3n0
### - script improved by Persian Prince, https://github.com/persianpros for OV
#################################################################################
"

#################################################################################

create_srvid_file()
{
    # الرابط باستخدام HTTPS ووكيل مستخدم (User-Agent) حديث لتجاوز الحماية
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    if wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL" > /dev/null 2>&1; then
        echo "URL download successful:   ${URL}"
        
        # التعديل الجذري: استخدام grep و sed لتنظيف البيانات قبل إرسالها لـ awk
        # هذا يضمن أننا سنحصل على الـ SID والاسم حتى لو تغير شكل الكود
        grep -E 'class="(A3|s)"' /tmp/kos.html | sed 's/<[^>]*>//g' | sed 's/^[ \t]*//;s/[ \t]*$//' > /tmp/clean_data.txt
        
        awk -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            {
                # إذا كان السطر يحتوي على أرقام فقط فهو SID
                if ($0 ~ /^[0-9]+$/) {
                    sid = $0;
                    if (chname != "") {
                        printf "%s:%04X|%s|%s\n", CAIDS, sid, PROVIDER, chname;
                        chname = ""; # إعادة التصفير
                    }
                } else {
                    # إذا كان نصاً فهو اسم القناة
                    chname = $0;
                }
            }' /tmp/clean_data.txt > "/tmp/oscam__${1,,}.srvid"
        
        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo -e "The new file was created:  /tmp/oscam__${1,,}.srvid\n"
        else
            echo -e "Warning: No data extracted. Structure might have changed.\n"
        fi
        rm -f /tmp/kos.html /tmp/clean_data.txt
    else
        echo "URL download failed !!! URL:  ${URL}"
    fi
}

#################################################################################

echo "$HEADER"

OSCAM_SRVID="oscam.srvid"

# Check https://en.kingofsat.net/packages.php for possible package updates
# Check https://wiki.streamboard.tv/wiki/Srvid for possible CaID

### create temporary ".srvid" files:
# ملاحظة: جرب باقة واحدة للتأكد من النتيجة
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"
create_srvid_file "skygermany" "098C,09C4,098D"
create_srvid_file "skyitalia" "0919,093B,09CD"
create_srvid_file "skylink" "0D96,0624"
create_srvid_file "tivusat" "183D,183E,1856"

### تجميع الملفات:
echo "$HEADER" > $OSCAM_SRVID
echo -e "### File creation date: $(date '+%Y-%m-%d')\n" >> $OSCAM_SRVID
cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

[ -f "$OSCAM_SRVID" ] && echo "All generated '.srvid' files have been merged into: ${OSCAM_SRVID}"
