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
    # التعديل: استخدام رابط HTTPS وإضافة Header يحاكي المتصفحات الحديثة بدقة
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    
    # محاكاة متصفح حقيقي بالكامل لتجاوز الحماية
    USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    REFERER="https://en.kingofsat.net/"

    if wget -q -O /tmp/kos.html --user-agent="$USER_AGENT" --header="Referer: $REFERER" --no-check-certificate "$URL"; then
        echo "URL download successful:   ${URL}"
        
        # التعديل: منطق AWK معدل ليبحث عن الأسماء والـ SIDs في الكود الجديد للموقع
        # قمت بتغيير طريقة استخراج البيانات لتعتمد على نصوص الجدول مباشرة
        awk -F '>' -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            BEGIN { CHNAME = "invalid" }
            /class="A3"/ { 
                # تنظيف النص لاستخراج اسم القناة
                n = split($2, a, "<");
                CHNAME = a[1];
                gsub(/^[ \t]+|[ \t]+$/, "", CHNAME);
            }
            /class="s"/ {
                # تنظيف النص لاستخراج الـ SID (رقم القناة)
                n = split($2, b, "<");
                SID = b[1];
                gsub(/[^0-9]/, "", SID); # التأكد أن الـ SID رقم فقط
                if (CHNAME != "invalid" && SID != "") {
                    printf "%s:%04X|%s|%s\n", CAIDS, SID, PROVIDER, CHNAME;
                    CHNAME = "invalid";
                }
            }' /tmp/kos.html > "/tmp/oscam__${1,,}.srvid"
        
        # التحقق إذا كان الملف الناتج يحتوي على بيانات
        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
             echo -e "Success: Data extracted for ${1}\n"
        else
             echo -e "Warning: File created but no data found for ${1}. Site might be blocking script.\n"
        fi
        rm -f /tmp/kos.html
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
# ملاحظة: جرب باقة واحدة للتأكد
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"
create_srvid_file "skygermany" "098D,09C4"
create_srvid_file "skyitalia" "0919,093B,09CD"
create_srvid_file "skylink" "0D03,0D70,0D96,0624"
create_srvid_file "tivusat" "183D,183E,1856"

### تجميع الملفات:
echo "$HEADER" > $OSCAM_SRVID
echo -e "### File creation date: $(date '+%Y-%m-%d')\n" >> $OSCAM_SRVID
cat /tmp/oscam__* >> $OSCAM_SRVID 2>/dev/null
rm -f /tmp/oscam__*

if [ -s "$OSCAM_SRVID" ]; then
    echo "All generated '.srvid' files have been merged into: ${OSCAM_SRVID}"
else
    echo "Error: Final file is empty. Please check internet connection or site access."
fi
