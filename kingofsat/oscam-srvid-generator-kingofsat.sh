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
    # INPUT ARGUMENTS:
    #    $1 = the URL of the package list of channels with their data, on a specific http://en.KingOfSat.net/pack-XXXXX.php website (see below)
    #    $2 = CAIDs (separated by comma) what is necessary for the provider
    #
    # EXAMPLE:      create_srvid_file "skylink" "0D96,0624"
    #
    # NOTE:         "${1^}" provides the first-character-upper string = "Provider"     "${1^^}" provides the upper-case string = "PROVIDER"     "${1}" provides the string = "provider"     "${1,,}" provides the lower-case string = "provider"
    
    URL="http://en.kingofsat.net/pack-${1,,}.php"
    
    if wget -q -O /tmp/kos.html --no-check-certificate "$URL" > /dev/null 2>&1; then
        echo "URL download successful:   ${URL}"
        
        awk -F '>' -v CAIDS="${2}" -v PROVIDER="${1^^}" -e '
            BEGIN { CHNAME = "invalid" }
            /<i>|class="A3"/ { CHNAME = substr($2,1,length($2) - 3) }
            /class="s">[0-9]+/ {
                SID = substr($2,1,length($2) - 4)
                if (CHNAME == "invalid") next
                printf "%s:%04X|%s|%s\n", CAIDS, SID, PROVIDER, CHNAME
                CHNAME = "invalid"
              }' /tmp/kos.html > "/tmp/oscam__${1,,}.srvid"
        
        echo -e "The new file was created:  /tmp/oscam__${1,,}.srvid\n"
        rm -f /tmp/kos.html
    else
        echo "URL download failed !!! URL:  ${URL}"
    fi
}

#################################################################################

echo "$HEADER"

#OSCAM_SRVID="/tmp/oscam_-_merged-kingofsat.srvid"
OSCAM_SRVID="oscam.srvid"

### create temporary ".srvid" files:
create_srvid_file "a1bg" "0B00,FFFE"
create_srvid_file "antiksat" "0B00,FFFE"
create_srvid_file "abscbn" "0604,FFFE"
create_srvid_file "akta" "0500,0B00,FFFE"
create_srvid_file "austriasat" "0D05,FFFE"
create_srvid_file "bis" "0500,0100,1819,FFFE"
create_srvid_file "boom" "0929,FFFE"
create_srvid_file "bulsatcom" "0604,5501,5581,4AEE,FFFE"
create_srvid_file "cosmote" "09BE,095E,FFFE"
create_srvid_file "canaldigitaal" "0100,0622,0624,181D,0653,0B02,0D69"
create_srvid_file "canaldigitalnordic" "0B00,FFFE"
create_srvid_file "canal" "0500,0100,1811,FFFE"
create_srvid_file "cplus26e" "0500,FFFE"
create_srvid_file "cslink" "0D0F,0666,FFFE"
create_srvid_file "directone" "0D97,0653,0B02,1815,FFFE"
create_srvid_file "digitalb" "0B00,1830,069B,091F,0911,069F,FFFE"
create_srvid_file "digitalplusa" "0100,1810,FFFE"
create_srvid_file "digitalplush" "1810,FFFE"
create_srvid_file "digiturk" "0D00,0664,FFFE"
create_srvid_file "digitv" "1802,1880,FFFE"
create_srvid_file "dmc" "0D04,FFFE"
create_srvid_file "dolcetv" "092F,FFFE"
create_srvid_file "dsmart" "092B,FFFE"
create_srvid_file "focussat" "0B02,FFFE"
create_srvid_file "fransat" "0500,FFFE"
create_srvid_file "hdplus" "1830,FFFE"
create_srvid_file "hellohd" "0BAA,FFFE"
create_srvid_file "kabeld" "1834,1722,09C7,FFFE"
create_srvid_file "kabelkiosk" "0B00,098D,09AF,1840,0BC1,09C4,098C"
create_srvid_file "maxtv" "1830,0B00,069B,FFFE"
create_srvid_file "mcafrica" "1800,FFFE"
create_srvid_file "mediaset" "1803,FFFE"
create_srvid_file "meo" "0100,1814,FFFE"
create_srvid_file "mobistar" "0500,FFFE"
create_srvid_file "mtv" "0B00,0D00,FFFE"
create_srvid_file "multicanal" "1802,FFFE"
create_srvid_file "mytv" "1800,FFFE"
create_srvid_file "ncplus" "0100,0B01,1813,0500,1884"
create_srvid_file "nos" "1802,FFFE"
create_srvid_file "nova" "0604,0699"
create_srvid_file "neosat" "4AEE,FFFE"
create_srvid_file "orange" "0500,1811,FFFE"
create_srvid_file "orangepl" "0500,FFFE"
create_srvid_file "orbit" "0100,0668,FFFE"
create_srvid_file "orfdigital" "0650,0D05,0D95,0D98,0648,09C4,06E2,098C,098D,FFFE"
create_srvid_file "ote" "099E,FFFE"
create_srvid_file "platformadv" "4AE1,FFFE"
create_srvid_file "platformahd" "4AE1,FFFE"
create_srvid_file "ncplus" "0100,0B01,1813,0500,1884"
create_srvid_file "polsat" "1803,1861,1884,0500,1870,06ED,186C,0B01"
create_srvid_file "pink" "0629,091F,0911,069F"
create_srvid_file "raduga" "0652,FFFE"
create_srvid_file "rai" "0100,183D,1856,183E"
create_srvid_file "satellitebg" "0D06,0D96,0B01,0624,FFFE"
create_srvid_file "showtime" "0100,0668,FFFE"
create_srvid_file "skydigital" "0963,FFFE"
create_srvid_file "skygermany" "1833,1834,1702,1722,09C4,09AF,098D,0650,0D05,0D95,0D98,0648,06E2,098C"
create_srvid_file "skyitalia" "0919,093B,09CD,FFFE"
create_srvid_file "skylink" "0D03,0D70,0D96,0624,181D,0653,0B02,0D69"
create_srvid_file "ssr" "0500,FFFE"
create_srvid_file "telesat" "0100,0500,1819"
create_srvid_file "tivusat" "183D,183E,1856,09CD,0B02"
create_srvid_file "totaltv" "091F,FFFE"
create_srvid_file "tring" "0BAA,FFFE"
create_srvid_file "tvnakarte" "0B00,FFFE"
create_srvid_file "tvp" "09B2,FFFE"
create_srvid_file "tvvlaanderen" "0100,0500,1818,1819,181D,0624,181D,0653,0B02,0D69"
create_srvid_file "upc" "0D02,1815,0D97,0653,FFFE"
create_srvid_file "viasat" "090F,093E,FFFE"
create_srvid_file "visiontv" "0931,FFFE"
create_srvid_file "vivacom" "09BD,FFFE"
create_srvid_file "viasatua" "5604,FFFE"
create_srvid_file "volnatelka" "0668,069A"
create_srvid_file "xtra" "0000"
create_srvid_file "zdfvision" "FFFE"
### merge all generated ".srvid" files into one file + move this new file to the Oscam config-dir:
echo "$HEADER" > $OSCAM_SRVID
echo -e "### File creation date: $(date '+%Y-%m-%d')\n" >> $OSCAM_SRVID
cat /tmp/oscam__* >> $OSCAM_SRVID
rm -f /tmp/oscam__*
[ -f "$OSCAM_SRVID" ] && echo "All generated '.srvid' files have been merged into one and moved to the directory:  ${OSCAM_SRVID}"

