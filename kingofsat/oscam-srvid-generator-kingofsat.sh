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
    # التعديل: استخدام HTTPS وإضافة وكيل مستخدم حديث
    URL="https://en.kingofsat.net/pack-${1,,}.php"
    UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    # تحميل الصفحة بصمت
    if wget -q -O /tmp/kos.html --user-agent="$UA" --no-check-certificate "$URL"; then
        echo "URL download successful: ${URL}"
        
        # التعديل: منطق awk جديد تماماً وأكثر دقة لسحب الـ SID والاسم
        awk -F '>' -v CAIDS="${2}" -v PROVIDER="${1^^}" '
            /class="A3"/ { 
                # استخراج اسم القناة من التاج A3
                split($2, a, "<"); 
                temp_name = a[1];
            }
            /class="s"/ {
                # استخراج الـ SID من التاج s
                split($2, b, "<");
                temp_sid = b[1];
                # تنظيف الـ SID من أي مسافات والتأكد أنه رقم
                gsub(/[[:space:]]/, "", temp_sid);
                if (temp_name != "" && temp_sid ~ /^[0-9]+$/) {
                    printf "%s:%04X|%s|%s\n", CAIDS, temp_sid, PROVIDER, temp_name;
                    temp_name = ""; # تصفير المتغيرات للدورة القادمة
                }
            }' /tmp/kos.html > "/tmp/oscam__${1,,}.srvid"
        
        # التأكد إذا كان الملف الناتج يحتوي على بيانات فعلاً
        if [ -s "/tmp/oscam__${1,,}.srvid" ]; then
            echo -e "Success: Data extracted to /tmp/oscam__${1,,}.srvid\n"
        else
            echo -e "Warning: No data found in the page structure for ${1}.\n"
        fi
        rm -f /tmp/kos.html
    else
        echo "URL download failed !!! URL: ${URL}"
    fi
}

#################################################################################

echo "$HEADER"

OSCAM_SRVID="oscam.srvid"

echo "### File creation date: $(date '+%Y-%m-%d')" > $OSCAM_SRVID

### create temporary ".srvid" files:
# جرب تشغل باقة واحدة زي beIN للتأكد
create_srvid_file "bein" "0500"
create_srvid_file "osn" "0604"
create_srvid_file "art" "0604"
create_srvid_file "skygermany" "098D,09C4"
create_srvid_file "skyitalia" "0919,093B,09CD"

### تجميع الملفات:
cat /tmp/oscam__* >> $OSCAM_SRVID
rm -f /tmp/oscam__*

[ -f "$OSCAM_SRVID" ] && echo "Done! Final file saved as: ${OSCAM_SRVID}"
