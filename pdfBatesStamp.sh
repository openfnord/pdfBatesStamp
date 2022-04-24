#!/bin/bash -
#
# "Bates-stamp" a PDF file with text (only; images aren't supported).  Uses
# ghostscript (ps2pdf) and pdfdk.
#
# The output (Bates-stamped) file is put in the same directory, with "_BATES"
# appended to its name, thusly:
#     pdfBatesStamp.sh <FILE>.pdf ==> <FILE>_BATES.pdf
#
# Usage:
#     pdfBatesStamp.sh <FILE>.pdf [PREFIX(def=<FILE>)] [STARTNUM(def=1)]
#     pdfBatesStamp.sh <FILE>.pdf BATESCONFIG=<bates_config_filename>
#
# The <FILE>.pdf name must end in ".pdf".  You can make many more settings
# inline below (you can also set PREFIX and STARTNUM there too if you want).
# The first invocation format above is for the most common case (e.g., for legal
# use).  In the second invocation format, the <bates_config_filename> file can
# contain any of the inline user-settings (below, from PREFIX to EXTRAS,
# inclusive), and they will overwrite the inline settings.  In this way, you can
# write/store special config file settings for special PDFs, without needing to
# modify the inline settings each time.  Runs at ~3 pages/sec.
#
# Copyright (C) 2014 Walter Tuvell.  Contributed to the Public Domain.


################################################################################
#################### USERS: SPECIFY YOUR CONFIG PARAMS HERE ####################
################################################################################

# These default settings are tuned for an unspecified PREFIX and STARTNUM,
# yielding a Bates stamp consisting of: the FILE's name; followed 6 spaces;
# followed by the Bates/page number; in the SouthWest corner; with colors I
# like.  You can specify any FONT installed on the machine, according to
# fontconfig (see "fc-list" command); the 35 PostScript standard fonts always
# work; if the specified FONT can't be found, defaults to PostScript Courier.
# Recall that PostScript point = 1/72".
PREFIX=                  # if present, this gets first priority; else command-line; else <FILE>name
STARTNUM=                # if present, this gets first priority; else command-line; 1 {int>=0; 0 means no Bates/page number}
SUFFIX=                  # follows the Bates/page number; you can include spaces if you want, even leading/trailing ones
NUMPAD=0                 # pad Bates/page number with leading 0's {int>=0}
SPACEPAD=6               # number of spaces between PREFIX and Bates/page number {int>=0}
LOCATION=SouthWest       # NorthWest, North, NorthEast, SouthWest, South, SouthEast,
                         #   WestNorth, West,  WestSouth, EastNorth, East,  EastSouth
FONT=Helvetica-Bold      # "perfect" font for Bates-stamp (a PostScript standard font)
FONTSIZE=10.0            # "perfect" size for Bates-stamp; pts {float>0.0}
FONTCOLOR=128/0/0        # maroon = rgb(128,0,0) {int 0..255}
MARGIN=21/21/21/21       # indent of stamp from page edge(s); pts left/bot/right/top {float>0.0}
HIGHLIGHT=-1             # 0.0 means no highlight; <0.0 means fill; >0.0 means outline thickness {float}
HLCOLOR=240/230/140      # (light)khaki = rgb(240,230,140) {int 0..255}
HLTWEAK=0/0/0/0          # highlight tweaks for special cases; pts left/bot/right/top {float>=0.0}
# The following EXTRAS define additional stamps (i.e., beyond the basic Bates
# stamp, above).  If specified (i.e., its PREFIX is non-empty), these can have
# their own settings; if empty, their settings inherit from the main stamp's
# settings.  Each line of EXTRAS, if present at all, must contain all 9 entries
# (some possibly empty); the locations of EXTRAS are not allowed to collide (for
# example, NorthWest and WestNorth).  The maximum number of EXTRAS is 7, giving
# a total of 8 printing positions, counting the main Bates stamp itself.  Note
# that MARGIN is global (cannot be changed via EXTRAS).
EXTRAS=(
  # PREFIX  STARTNUM  SUFFIX  NUMPAD  SPACEPAD  LOCATION  FONT  FONTSIZE  FONTCOLOR  HIGHLIGHT  HLCOLOR  HLTWEAK
    ""      ""        ""      ""      ""        ""        ""    ""        ""         ""         ""       ""
)

# EXAMPLES:

# 1. Sampler.
# In the following EXTRAS Sampler, note that ZapfChancery and Symbol don't
# follow the "normal font rules", which causes "bounding box overflow" unless we
# do some tweaking.  HLTWEAK specifies the additional amount by which to modify
# the highlight box.  Positive makes the highlight box bigger in the direction
# specified, negative makes it smaller.  Another reason to use HLTWEAK is if
# want to fine-tune the way the highlight fits around the stamp, esp. if you use
# an outline of large thickness (>> 1.0).  HLTWEAK only adjusts the highlight
# box, not the stamp itself; the stamp remains in its regular place, at
# distance(s) MARGIN from the closest edge(s) of the page.
#EXTRAS=(
#    "The NorthWest"  "11"  "nw"  "1"  "7"  "NorthWest"  "Times-Roman"                "18"    "0/255/0"      "-1"   "0/0/255"      ""
#    "The North"      "22"  "n"   "2"  "6"  "North"      "ZapfChancery-MediumItalic"  "20"    "0/0/255"      "1.0"  "0/255/0"      "0/3/0/0"
#    "The EastNorth"  "33"  "en"  "3"  "5"  "EastNorth"  "Bookman-Demi"               "16"    "255/0/0"      ""     ""             ""
#    "The East"       "44"  "e"   "4"  "4"  "East"       "Palatino-BoldItalic"        "17.5"  "255/255/255"  "-1"   "0/0/0"        ""
#    "The SouthEast"  "55"  "se"  "5"  "3"  "SouthEast"  "NewCenturySchlBk-Roman"     ""      ""             ""     ""             "0/21/21/0"
#    "The South"      "66"  "s"   "6"  "2"  "South"      "Symbol"                     "28"    "255/255/0"    "0.1"  "128/128/128"  "0/4.5/0/0"
#    "The West"       "77"  "w"   "7"  "1"  "West"       "Courier-Bold"               "24"    "0/255/255"    "5"    "224/224/224"  "3/3/3/3"
#)

# 2. Legal.
# In legal practice, lawyers typically use settings similar to the following:
# PREFIX=                # specified on command-line; party name (no spaces, all-caps)
# STARTNUM=              # specified on command-line; 1 initially (updated for subsequent filings)
# SUFFIX=                # no suffix
# NUMPAD=6               # anticipating < 1,000,000 pages
# SPACEPAD=0             # no spaces in the Bates stamps
# LOCATION=SouthEast     # lower-right corner is the most common
# FONT=Times-Roman       # very conservative; one of the 35 PostScript standard fonts
# FONTSIZE=12            # nice and big
# FONTCOLOR=0/0/0        # black = rgb(0,0,0)
# MARGIN=6/6/6/6         # small, trying to avoid overwriting anything on the page
# HIGHLIGHT=0            # no highlight
# HLCOLOR=255/255/255    # white = rgb(255,255,255), but irrelevant here because HIGHLIGHT=0
# HLTWEAK=0/0/0/0        # no highlight tweaks needed or desired
# EXTRAS=(
#     "CONFIDENTIAL"   "SouthWest"   ""   ""   ""   ""   ""   ""
# )


################################################################################
##################### USERS: DON'T WRITE BELOW THIS LINE!! #####################
################################################################################

# Process args.

[ $# -ge 1 -a $# -le 3 ] || { echo "*** USAGE: batesStamp.sh FILE.pdf [PREFIX(def=FILE)] [STARTNUM(def=1)]"; exit 99; }

INFILENAME="$1"
[[ "$INFILENAME" =~ ^.*\.pdf$ ]] || { echo "*** Filename must end in \".pdf\""; exit 99; }
[ -e "$INFILENAME" ]  || { echo "*** Can't find file \"$INFILENAME\""; exit 99; }
INFILENAME=$(readlink -f "$INFILENAME")  # full/canonical filename
INFILEDIR=$(dirname "$INFILENAME")
INFILEBASE=$(basename "$INFILENAME")
INFILECORE=$(echo "$INFILEBASE" | sed -e 's/^\(.*\)\.pdf$/\1/' -)

OUTFILENAME="$INFILEDIR/${INFILECORE}_BATES.pdf"

# Check for 1st/2nd invocation format.
# In the 1st invocation format, the ranking of priority for PREFIX and STARTNUM is:
#   1. Inline in this file (above).
#   2. Command-line.
#   3. Default: PREFIX=<FILE>name; STARTNUM=1.
if [ $# -eq 3 ]; then
    cmdlinePREFIX="$2"
    cmdlineSTARTNUM="$3"
elif [ $# -eq 2 ]; then
    if [[ "$2" =~ BATESCONFIG=.* ]]; then
        # 2nd invocation format.
        BATESCONFIGFILE=$(echo "$2" | sed -e 's/BATESCONFIG=\(.*\)/\1/')
        source "$BATESCONFIGFILE"
    else
        cmdlinePREFIX="$2"
        cmdlineSTARTNUM=""
    fi
else
    cmdlinePREFIX=""
    cmdlineSTARTNUM=""
fi
PREFIX=${PREFIX:-$cmdlinePREFIX}
PREFIX=${PREFIX:-$INFILECORE}
[ -z "$PREFIX" ] && PREFIX="$INFILECORE"
STARTNUM=${STARTNUM:-$cmdlineSTARTNUM}
STARTNUM=${STARTNUM:-1}  # def = 1
[ "$STARTNUM" -ge 0 ] || { echo "*** STARTNUM must be >= 0"; exit 99; }

# Check MARGIN.
MARGIN=$(echo $MARGIN | tr "/" " ")
[ $(echo "$MARGIN" | wc -w) -eq 4 ] || { echo "*** Bad MARGIN \"$MARGIN\""; exit 99; }
for MARG in $MARGIN; do
    [ $(echo "scale=0; ($MARG)>0.0" | bc -q) -eq 1 ] || { echo "*** Bad MARGIN \"$MARGIN\""; exit 99; }
done

# Check SUFFIX.
:  # nothing to check (SUFFIX can be any string)

# Check NUMPAD.
[ "$NUMPAD" -ge 0 ] || { echo "*** Bad NUMPAD \"$NUMPAD\""; exit 99; }

# Check SPACEPAD, and append that number of space chars to PREFIX.
[ "$SPACEPAD" -ge 0 ] || { echo "*** Bad SPACEPAD \"$SPACEPAD\""; exit 99; }

# Prepare to check location; preparation needed because we want
# to keep track of "position", for collision detection, below.
LOCATIONS="NorthWest North NorthEast SouthWest South SouthEast
           WestNorth West  WestSouth EastNorth East  EastSouth"
POSITIONS="UpperLeft Upper UpperRight Right LowerRight Lower LowerLeft Left"
declare -A POSITIONS_USED  # Bash associative array
for POS in $POSITIONS; do
    POSITIONS_USED[$POS]=0
done
function positionUsed {
    case $1 in
        NorthWest|WestNorth) POSITIONS_USED[UpperLeft]=$((POSITIONS_USED[UpperLeft]+1)) ;;
        North)               POSITIONS_USED[Upper]=$((POSITIONS_USED[Upper]+1)) ;;
        NorthEast|EastNorth) POSITIONS_USED[UpperRight]=$((POSITIONS_USED[UpperRight]+1)) ;;
        East)                POSITIONS_USED[Right]=$((POSITIONS_USED[Right]+1)) ;;
        SouthEast|EastSouth) POSITIONS_USED[LowerRight]=$((POSITIONS_USED[LowerRight]+1)) ;;
        South)               POSITIONS_USED[Lower]=$((POSITIONS_USED[Lower]+1)) ;;
        SouthWest|WestSouth) POSITIONS_USED[LowerLeft]=$((POSITIONS_USED[LowerLeft]+1)) ;;
        West)                POSITIONS_USED[Left]=$((POSITIONS_USED[Left]+1)) ;;
        *)                   echo "*** NOT REACHED"; exit 99 ;;
    esac
}

# Now we can check location.
OK=NOTOK
for LOC in $LOCATIONS; do
    [ "$LOCATION" == $LOC ] && { OK=OK; break; }
done
[ $OK == OK ] || { echo "*** Can't find LOCATION=\"$LOCATION\""; exit 99; }
# And record the location's position.
positionUsed $LOCATION

# No need to check font -- just default to Courier if specified font not found.
# The PostScript standard fonts.
#STDFONTS="
#    AvantGarde-Book         AvantGarde-BookOblique        AvantGarde-Demi                AvantGarde-DemiOblique
#    Bookman-Demi            Bookman-DemiItalic            Bookman-Light                  Bookman-LightItalic
#    Courier                 Courier-Bold                  Courier-BoldOblique            Courier-Oblique
#    Helvetica               Helvetica-Bold                Helvetica-BoldOblique          Helvetica-Oblique
#    Helvetica-Narrow        Helvetica-Narrow-Bold         Helvetica-Narrow-BoldOblique   Helvetica-Narrow-Oblique
#    NewCenturySchlBk-Bold   NewCenturySchlBk-BoldItalic   NewCenturySchlBk-Italic        NewCenturySchlBk-Roman
#    Palatino-Bold           Palatino-BoldItalic           Palatino-Italic                Palatino-Roman
#    Times-Bold              Times-BoldItalic              Times-Italic                   Times-Roman
#    Symbol                  ZapfChancery-MediumItalic     ZapfDingbats
#"
#function checkFont {
#    OK=NOTOK
#    for F in $STDFONTS; do
#        [ "$1" == $F ] && { OK=OK; break; }
#    done
#    [ $OK == OK ] || { echo "*** Bad FONT \"$1\" (not one of the 35 standard PostScript fonts)"; exit 99; }
#}
#checkFont "$FONT"


# Check FONTSIZE.
function checkFontsize {
    [ $(echo "scale=9; ($1)>0.0" | bc -q) -eq 1 ] || { echo "*** Bad FONTSIZE \"$1\""; exit 99; }
}
checkFontsize "$FONTSIZE"

# Map RGB colors from 3-byte 0..255 standard) to PostScript 3-number 0.0..1.0.
function mapRGB {
    echo "scale=9; ($1)/255.0" | bc -q
}
function mapColor {
    RGBCOLOR="$1"
    TMPCOLOR=($(echo $RGBCOLOR | tr "/" " "))
    [ $(echo ${TMPCOLOR[*]} | wc -w) -eq 3 ] || { echo "*** Malformed COLOR"; exit 99; }
    for I in 0 1 2; do
        [ 0 -le ${TMPCOLOR[I]} -a ${TMPCOLOR[I]} -le 255 ] || { echo "*** Bad COLOR \"${TMPCOLOR[I]}\""; exit 99; }
    done
    echo "$(mapRGB ${TMPCOLOR[0]}) $(mapRGB ${TMPCOLOR[1]}) $(mapRGB ${TMPCOLOR[2]})"
}

FONTCOLOR="$(mapColor $FONTCOLOR)"
HLCOLOR="$(mapColor $HLCOLOR)"

# Check HIGHLIGHT.
function checkHighlight {
    [ $(echo "scale=9; ($1)==0.0 || ($1)*($1)>0.0" | bc -q) -eq 1 ] || { echo "*** Bad HIGHLIGHT \"$1\""; exit 99; }
}
checkHighlight "$HIGHLIGHT"

# Separate HLTWEAK into 4 pieces.
function mapHlTweak {
    echo "$1" | tr "/" " "
}
HLTWEAK="$(mapHlTweak $HLTWEAK)"

# Handle EXTRAS.
SIZEEXTRAS=${#EXTRAS[*]}
SIZEENTRY=12
[ $((SIZEEXTRAS % SIZEENTRY)) -eq 0 ] || { echo "*** Malformed EXTRAS"; exit 99; }
NUMEXTRAS=$((SIZEEXTRAS / SIZEENTRY))
[ $NUMEXTRAS -le 7 ] || { echo "*** Too many EXTRAS"; exit 99; }
#NUMEXTRAS_1=$((NUMEXTRAS-1))
for (( N=0; N<NUMEXTRAS; N+=1 )); do
    # EXTRA PREFIX.
    if [ -z "${EXTRAS[N*SIZEENTRY+0]}" ]; then
        continue  # if PREFIX is empty, ignore other entries
    fi
    # EXTRA STARTNUM.
    [ -z "${EXTRAS[N*SIZEENTRY+1]}" ] && EXTRAS[N*SIZEENTRY+1]=$STARTNUM  # inherit
    [ -z "${EXTRAS[N*SIZEENTRY+1]}" ] && EXTRAS[N*SIZEENTRY+1]=1  # def = 1
    [ "${EXTRAS[N*SIZEENTRY+1]}" -ge 0 ] || { echo "*** EXTRA STARTNUM must be >= 0"; exit 99; }
    # EXTRA SUFFIX.
    [ -z "${EXTRAS[N*SIZEENTRY+2]}" ] && EXTRAS[N*SIZEENTRY+2]="$SUFFIX"  # inherit
    # EXTRA NUMPAD.
    [ -z "${EXTRAS[N*SIZEENTRY+3]}" ] && EXTRAS[N*SIZEENTRY+3]=$NUMPAD  # inherit
    [ "${EXTRAS[N*SIZEENTRY+3]}" -ge 0 ] || { echo "*** Bad EXTRA NUMPAD \"${EXTRAS[N*SIZEENTRY+3]}\""; exit 99; }
    # EXTRA SPACEPAD.
    [ -z "${EXTRAS[N*SIZEENTRY+4]}" ] && EXTRAS[N*SIZEENTRY+4]=$SPACEPAD  # inherit
    [ "${EXTRAS[N*SIZEENTRY+4]}" -ge 0 ] || { echo "*** Bad EXTRA SPACEPAD \"${EXTRAS[N*SIZEENTRY+4]}\""; exit 99; }
    # EXTRA LOCATION.  (No inheritance of LOCATION.)
    OK=NOTOK
    for LOC in $LOCATIONS; do
        [ "${EXTRAS[N*SIZEENTRY+5]}" == $LOC ] && { OK=OK; break; }
    done
    [ $OK == OK ] || { echo "*** Can't find EXTRA LOCATION=\"${EXTRAS[N*SIZEENTRY+5]}\""; exit 99; }
    positionUsed ${EXTRAS[N*SIZEENTRY+5]}
    # EXTRA FONT.
    if [ -z "${EXTRAS[N*SIZEENTRY+6]}" ]; then
        EXTRAS[N*SIZEENTRY+6]="$FONT"  # inherit
    else
        : #checkFont "${EXTRAS[N*SIZEENTRY+6]}"
    fi
    # EXTRA FONTSIZE.
    if [ -z "${EXTRAS[N*SIZEENTRY+7]}" ]; then
        EXTRAS[N*SIZEENTRY+7]="$FONTSIZE"  # inherit
    else
        checkFontsize "${EXTRAS[N*SIZEENTRY+7]}"
    fi
    # EXTRA FONTCOLOR.
    if [ -z "${EXTRAS[N*SIZEENTRY+8]}" ]; then
        EXTRAS[N*SIZEENTRY+8]="$FONTCOLOR"  # inherit
    else
        EXTRAS[N*SIZEENTRY+8]="$(mapColor ${EXTRAS[N*SIZEENTRY+8]})"
    fi
    # EXTRA HIGHLIGHT.
    if [ -z "${EXTRAS[N*SIZEENTRY+9]}" ]; then
        EXTRAS[N*SIZEENTRY+9]="$HIGHLIGHT"  # inherit
    else
        checkHighlight "${EXTRAS[N*SIZEENTRY+9]}"
    fi
    # EXTRA HLCOLOR.
    if [ -z "${EXTRAS[N*SIZEENTRY+10]}" ]; then
        EXTRAS[N*SIZEENTRY+10]="$HLCOLOR"  # inherit
    else
        EXTRAS[N*SIZEENTRY+10]="$(mapColor ${EXTRAS[N*SIZEENTRY+10]})"
    fi
    # EXTRA HLTWEAK.
    if [ -z "${EXTRAS[N*SIZEENTRY+11]}" ]; then
        EXTRAS[N*SIZEENTRY+11]="$HLTWEAK"  # inherit
    else
        EXTRAS[N*SIZEENTRY+11]="$(mapHlTweak ${EXTRAS[N*SIZEENTRY+11]})"
    fi
done

# Check to make sure no 2 locations collide in any position.
for POS in $POSITIONS; do
    [ ${POSITIONS_USED[$POS]} -ge 2 ] && { echo "*** Location collision at $POS"; exit 99; }
done

# PDFTK doesn't seem to have a way to discover page geometry (PDWIDTH & PGHEIGHT,
# in PostScript points), so here are helper(s) to do the job.
# We try both ImageMagick "identify" and Poppler "pdfindo" (randomly), if
# they're installed; else we just do it by hand (by grep'ing the PDF file).
function tryIDENTIFY {
    IDENTIFY=($(identify $1 2>/dev/null))  # bash array
    if [ $? -eq 0 ]; then
        GEOMETRY=($(echo ${IDENTIFY[2]} | tr "x" " "))  # bash array -- $IDENTIFY[2] is of the form PGWIDTHxPGHEIGHT
        PGWIDTH=${GEOMETRY[0]}; PGHEIGHT=${GEOMETRY[1]}
        return 0
    else
        return 99
    fi
}
function tryPDFINFO {
    PDFINFO=($(pdfinfo -meta $1 | grep '^Page size:' |  \
             sed -e 's/^Page size: *\([0-9][0-9]*\) x \([0-9][0-9]*\) pts.*$/\1 \2/'))  # bash array
    if [ $? -eq 0 ]; then
        PGWIDTH=${PDFINFO[0]}; PGHEIGHT=${PDFINFO[1]}
        return 0
    else
        return 99
    fi
}
function tryGREPSED {
    MEDIABOXLINE=$(grep -a /MediaBox $1)
    [ $(echo $MEDIABOXLINE | wc -l) -eq 1 ] || return 99
    GREPSED=($(echo "$MEDIABOXLINE" |  \
               sed -e 's#/.*/MediaBox\[ *\([\.0-9-]*\) *\([\.0-9-]*\) *\([\.0-9-]*\) *\([\.0-9-]*\).*#\1 \2 \3 \4#' |  \
               sed -e 's#^<<##'))  # bash array
    [ $? -eq 0 ] || return 99
    PGWIDTH=$(echo "scale=9; (${GREPSED[2]})-(${GREPSED[0]})" | bc -q)
    PGHEIGHT=$(echo "scale=9; (${GREPSED[3]})-(${GREPSED[1]})" | bc -q)
    return 0
}
function getGEOMETRY {
    PGWIDTH=-1; PGHEIGHT=-1
    case $((RANDOM%2)) in
        0) tryIDENTIFY $1
           EXITCODE=$?
           [ $EXITCODE -ne 0 ] && tryPDFINFO $1
           EXITCODE=$?
           ;;
        1) tryPDFINFO $1
           EXITCODE=$?
           [ $EXITCODE -ne 0 ] && tryIDENTIFY $1
           EXITCODE=$?
           ;;
        *) echo "*** NOT REACHED"; exit 99 ;;
    esac
    [ $EXITCODE -ne 0 ] && { tryGREPSED $1; EXITCODE=$?; }
    [ $EXITCODE -ne 0 ] && { echo "*** Can't find page size"; exit 99; }
    [ $(echo "scale=0; ($PGWIDTH)>0.0" | bc -q)  -eq 1 -a  \
      $(echo "scale=0; ($PGHEIGHT)>0.0" | bc -q) -eq 1    ] ||  \
        { echo "*** Can't find page size"; exit 99; }
}

# Trivial helpers.
function mult10 {
    echo "scale=9; ($1)*10.0" | bc -q | sed -e 's/\..*$//'  # truncate/round
}
function pt2in {
    echo "scale=3; ($1)/72.0" | bc -q
}
function fileSize {
    wc -c "$1" | cut -d' ' -f1
}
function pctIncrease {
    echo "scale = 9; (($2)/($1))*100.0" | bc -q |  sed -e 's/^\([0-9]*\.[0-9][0-9]\)[0-9]*$/\1/'  # truncate/round
}
function format3d {
    LC_ALL= printf "%'.3d\n" "$1"
}
function format3f {
    LC_ALL= printf "%'.3f\n" "$1"
}

# Non-trivial helper: Create text of stamp.
function makeSTAMP {
    tmpPREFIX="$1"
    [ -z "$tmpPREFIX" ] && { echo ""; return; }  # hack!
    tmpSTARTNUM="$2"
    tmpSUFFIX="$3"
    tmpNUMPAD="$4"
    tmpSPACEPAD="$5"
    tmpNUM="$6"
    for I in $(seq 1 $tmpSPACEPAD); do
        tmpPREFIX+=" "
    done
    if [ $tmpSTARTNUM -eq 0 ]; then
        tmpNUMFIX=""
    else
        tmpNUMFIX="$(LC_ALL=C printf %.${tmpNUMPAD}d $((tmpSTARTNUM+tmpNUM-1)))"
    fi
    echo "${tmpPREFIX}${tmpNUMFIX}${tmpSUFFIX}"
}

# Do all work in temp dir.
function cleanup {
    rm -rf "$TEMPDIR"
}
trap cleanup EXIT
ORIGDIR="$PWD"
TEMPDIR=$(mktemp -p /tmp -d)
#cp "$INFILENAME" $TEMPDIR/orig.pdf  # a known name, so we don't have name-collisions
ln -s "$INFILENAME" $TEMPDIR/orig.pdf  # a known name, so we don't have name-collisions
cd $TEMPDIR


# Main loop.
#
# Since the pages of the original may be of different size/orientation, so
# we must process each page individually.  To do that, we use pdftk burst.
pdftk orig.pdf burst output burst%d.pdf
[ $? -eq 0 ] || { echo "*** Can't do \"pdftk burst\""; exit 99; }
#rm -f orig.pdf  -- don't bother, it'll be deleted later
NUMPAGES=$(echo burst*.pdf | wc -w)
# Alternatively, we could have done the following (but we need to do "pdftk burst" anyway):
# NUMPAGES=$(pdftk orig.pdf dump_data output 2>/dev/null | grep NumberOfPages | cut -d" " -f 2)

INFILESIZE=$(fileSize $INFILENAME)
echo "Input File = \"$INFILENAME\"  (origSize=$(format3d $INFILESIZE))"

# Now loop through each page.
for (( NUM=1; NUM<=$NUMPAGES; NUM+=1 )); do

    # Get page's GEOMETRY (width & height, in pts).
    # This is the only thing we use the individual/burst pages for.
    getGEOMETRY burst$NUM.pdf  # this sets PGWIDTH & PGHEIGHT.

    # Cobble together STAMP.
    STAMP=$(makeSTAMP "$PREFIX" $STARTNUM "$SUFFIX" $NUMPAD $SPACEPAD $NUM)
    # Progress report, using VT100 terminal escape.
    printf "\33[2K\r$NUM/$NUMPAGES"

    # The main trick: hand-coded PostScript program.
    PSPROGRAM="

        %STACK: stamp(text) location margin[L|B|R|T] font fontsize fontcolor[R|G|B] highlight bgcolor[R|G|B] tweak[L|B|R|T]
        /doStamp {
            % Pick up 19 args from the stack.
            /theTweakT     exch def
            /theTweakR     exch def
            /theTweakB     exch def
            /theTweakL     exch def
            /theBgColorB   exch def
            /theBgColorG   exch def
            /theBgColorR   exch def
            /theHighlight  exch def
            /theFontColorB exch def
            /theFontColorG exch def
            /theFontColorR exch def
            /theFontSize   exch def
            /theFont       exch def
            /theMarginT    exch def
            /theMarginR    exch def
            /theMarginB    exch def
            /theMarginL    exch def
            /theLocation   exch def
            /theStamp      exch def

            % Set up font for this stamp.
            theFont findfont theFontSize scalefont setfont

            % Get string metrics.  Need TWO calculations to get it right (WTF)!!
            /strHeightWidth {  %STACK: string => height width
                % 1. Use stringwidth to get width, even with leading/trailing
                % spaces (but this doesn't give correct height).
                dup  %STACK: string string
                stringwidth  %STACK: string width height
                pop  %STACK: string width
                % 2. Use well-known PostScript idiom to get height (but this
                % doesn't give correct width with leading/trailing spaces).
                exch  %STACK: width string
                gsave
                  newpath 0 0 moveto  % start at origin, for simplicity
                  false charpath  flattenpath  pathbbox  % string on stack is consumed by this line
                grestore  %STACK: width llx lly urx(~width) ury=height
                4 2 roll  %STACK: width urx height llx lly
                pop pop   %STACK: width urx height
                2 1 roll  %STACK: width height urx
                pop       %STACK: width height
            } def
            theStamp strHeightWidth
            /stampHeight exch def  /stampWidth exch def

            % Set up corners of stamp in standard position (modified by location and margins, below).
            /llx 0   def                 /lly 0   def                  % lower-left corner of stamp
            /lrx llx stampWidth add def  /lry lly def                  % lower-right corner of stamp
            /ulx llx def                 /uly lly stampHeight add def  % upper-left corner of stamp
            /urx lrx def                 /ury uly def                  % upper-right corner of stamp

            gsave  % needed for multiple stamps (main Bates stamp plus the EXTRAS)

            % Translate lower-left corner, and rotate, according to LOCATION and MARGIN.
            theLocation (NorthWest) eq { theMarginL
                                         $PGHEIGHT stampHeight sub theMarginT sub
                                         translate                                 } if
            theLocation (North)     eq { $PGWIDTH 2.0 div stampWidth 2.0 div sub
                                         $PGHEIGHT stampHeight sub theMarginT sub
                                         translate                                 } if
            theLocation (NorthEast) eq { $PGWIDTH stampWidth sub theMarginR sub
                                         $PGHEIGHT stampHeight sub theMarginT sub
                                         translate                                 } if
            theLocation (SouthWest) eq { theMarginL
                                         theMarginB
                                         translate                                 } if
            theLocation (South)     eq { $PGWIDTH 2.0 div stampWidth 2.0 div sub
                                         theMarginB
                                         translate                                 } if
            theLocation (SouthEast) eq { $PGWIDTH stampWidth sub theMarginR sub
                                         theMarginB
                                         translate                                 } if
            theLocation (WestNorth) eq { stampHeight theMarginL add
                                         $PGHEIGHT stampWidth sub theMarginT sub
                                         translate  90.0 rotate                    } if
            theLocation (West)      eq { stampHeight theMarginL add
                                         $PGHEIGHT 2.0 div stampWidth 2.0 div sub
                                         translate  90.0 rotate                    } if
            theLocation (WestSouth) eq { stampHeight theMarginL add
                                         theMarginB
                                         translate  90.0 rotate                    } if
            theLocation (EastNorth) eq { $PGWIDTH stampHeight sub theMarginR sub
                                         $PGHEIGHT stampWidth sub theMarginT sub
                                         translate  90.0 rotate                    } if
            theLocation (East)      eq { $PGWIDTH stampHeight sub theMarginR sub
                                         $PGHEIGHT 2.0 div stampWidth 2.0 div sub
                                         translate  90.0 rotate                    } if
            theLocation (EastSouth) eq { $PGWIDTH stampHeight sub theMarginR sub
                                         theMarginB
                                         translate  90.0 rotate                    } if

            % Now that we're all set up, we can paint our stamp & highlight.

            % First draw the highlight.
            theHighlight 0.0 ne {
                % Define highlight metrics, to perfectly surround the text of the stamp, with
                % default (1/6)*FONTSIZE bump-out for good fit (user can always tweak via HLTWEAK).
                /hlBump theFontSize 6.0 div def
                /llxH llx hlBump sub def  /llyH lly hlBump sub def  % lower-left corner of highlight
                /lrxH lrx hlBump add def  /lryH lry hlBump sub def  % lower-right corner of highlight
                /ulxH ulx hlBump sub def  /ulyH uly hlBump add def  % upper-left corner of highlight
                /urxH urx hlBump add def  /uryH ury hlBump add def  % upper-right corner of highlight
                % Modify highlight for tweaks.
                /llxH llxH theTweakL sub def  /llyH llyH theTweakB sub def
                /lrxH lrxH theTweakR add def  /lryH lryH theTweakB sub def
                /ulxH ulxH theTweakL sub def  /ulyH ulyH theTweakT add def
                /urxH urxH theTweakR add def  /uryH uryH theTweakT add def
                theBgColorR theBgColorG theBgColorB  setrgbcolor
                newpath  % define path for highlight fill/stroke
                  llxH llyH moveto
                  lrxH lryH lineto
                  urxH uryH lineto
                  ulxH ulyH lineto
                  closepath
                  theHighlight 0.0 lt {
                      fill
                  } {
                      theHighlight setlinewidth  stroke
                  } ifelse
            } if

            % Then draw the text of the stamp on top of the highlight.
            theFontColorR theFontColorG theFontColorB  setrgbcolor
            llx lly moveto
            theStamp show

            grestore  % needed for multiple stamps

        } def

        % Do the deed.
        % Always do regular Bates-stamp.
        true {
            ($STAMP)
            ($LOCATION) $MARGIN
            ($FONT)     $FONTSIZE  $FONTCOLOR
            $HIGHLIGHT  $HLCOLOR   $HLTWEAK
            doStamp
        } if
        % Then do the EXTRAS, if any.
        $NUMEXTRAS 1 ge (${EXTRAS[0*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[0*SIZEENTRY+0]}" ${EXTRAS[0*SIZEENTRY+1]} "${EXTRAS[0*SIZEENTRY+2]}" ${EXTRAS[0*SIZEENTRY+3]} ${EXTRAS[0*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[0*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[0*SIZEENTRY+6]}) ${EXTRAS[0*SIZEENTRY+7]}  ${EXTRAS[0*SIZEENTRY+8]}
             ${EXTRAS[0*SIZEENTRY+9]}  ${EXTRAS[0*SIZEENTRY+10]} ${EXTRAS[0*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 2 ge (${EXTRAS[1*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[1*SIZEENTRY+0]}" ${EXTRAS[1*SIZEENTRY+1]} "${EXTRAS[1*SIZEENTRY+2]}" ${EXTRAS[1*SIZEENTRY+3]} ${EXTRAS[1*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[1*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[1*SIZEENTRY+6]}) ${EXTRAS[1*SIZEENTRY+7]}  ${EXTRAS[1*SIZEENTRY+8]}
             ${EXTRAS[1*SIZEENTRY+9]}  ${EXTRAS[1*SIZEENTRY+10]} ${EXTRAS[1*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 3 ge (${EXTRAS[2*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[2*SIZEENTRY+0]}" ${EXTRAS[2*SIZEENTRY+1]} "${EXTRAS[2*SIZEENTRY+2]}" ${EXTRAS[2*SIZEENTRY+3]} ${EXTRAS[2*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[2*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[2*SIZEENTRY+6]}) ${EXTRAS[2*SIZEENTRY+7]}  ${EXTRAS[2*SIZEENTRY+8]}
             ${EXTRAS[2*SIZEENTRY+9]}  ${EXTRAS[2*SIZEENTRY+10]} ${EXTRAS[2*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 4 ge (${EXTRAS[3*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[3*SIZEENTRY+0]}" ${EXTRAS[3*SIZEENTRY+1]} "${EXTRAS[3*SIZEENTRY+2]}" ${EXTRAS[3*SIZEENTRY+3]} ${EXTRAS[3*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[3*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[3*SIZEENTRY+6]}) ${EXTRAS[3*SIZEENTRY+7]}  ${EXTRAS[3*SIZEENTRY+8]}
             ${EXTRAS[3*SIZEENTRY+9]}  ${EXTRAS[3*SIZEENTRY+10]} ${EXTRAS[3*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 5 ge (${EXTRAS[4*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[4*SIZEENTRY+0]}" ${EXTRAS[4*SIZEENTRY+1]} "${EXTRAS[4*SIZEENTRY+2]}" ${EXTRAS[4*SIZEENTRY+3]} ${EXTRAS[4*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[4*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[4*SIZEENTRY+6]}) ${EXTRAS[4*SIZEENTRY+7]}  ${EXTRAS[4*SIZEENTRY+8]}
             ${EXTRAS[4*SIZEENTRY+9]}  ${EXTRAS[4*SIZEENTRY+10]} ${EXTRAS[4*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 6 ge (${EXTRAS[5*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[5*SIZEENTRY+0]}" ${EXTRAS[5*SIZEENTRY+1]} "${EXTRAS[5*SIZEENTRY+2]}" ${EXTRAS[5*SIZEENTRY+3]} ${EXTRAS[5*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[5*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[5*SIZEENTRY+6]}) ${EXTRAS[5*SIZEENTRY+7]}  ${EXTRAS[5*SIZEENTRY+8]}
             ${EXTRAS[5*SIZEENTRY+9]}  ${EXTRAS[5*SIZEENTRY+10]} ${EXTRAS[5*SIZEENTRY+11]}
            doStamp
        } if
        $NUMEXTRAS 7 ge (${EXTRAS[6*SIZEENTRY+0]}) () ne and {
            ("$(makeSTAMP "${EXTRAS[6*SIZEENTRY+0]}" ${EXTRAS[6*SIZEENTRY+1]} "${EXTRAS[6*SIZEENTRY+2]}" ${EXTRAS[6*SIZEENTRY+3]} ${EXTRAS[6*SIZEENTRY+4]} $NUM)")
            (${EXTRAS[6*SIZEENTRY+5]}) $MARGIN
            (${EXTRAS[6*SIZEENTRY+6]}) ${EXTRAS[6*SIZEENTRY+7]}  ${EXTRAS[6*SIZEENTRY+8]}
             ${EXTRAS[6*SIZEENTRY+9]}  ${EXTRAS[6*SIZEENTRY+10]} ${EXTRAS[6*SIZEENTRY+11]}
            doStamp
        } if

        %showpage  -- unnecessary

    "

    echo "$PSPROGRAM" |  \
        ps2pdf -dBATCH -g$(mult10 $PGWIDTH)x$(mult10 $PGHEIGHT) - stamp$NUM.pdf

done

printf "\33[2K\r"  # clear the report line

# Final steps.
STAMPLIST=$(ls -v stamp*.pdf)  # force correct ordering
# Concatenate the stamp pages, to create one big multi-stamp PDF,
# and pipe that to the PdfTk multi-stamp operation.
pdftk $STAMPLIST cat output - |  \
    pdftk orig.pdf multistamp - output "$OUTFILENAME"
OUTFILESIZE=$(fileSize "$OUTFILENAME")

# Done!
INCREASESIZE=$((OUTFILESIZE-INFILESIZE))
PCTINCREASE=$(pctIncrease $INFILESIZE $OUTFILESIZE)
echo "Output file = \"$OUTFILENAME\"  (batesSize=$(format3d $OUTFILESIZE); diffSizes=$(format3d ${INCREASESIZE})=${PCTINCREASE}%)"


################################################################################
#################################### DONE! #####################################
################################################################################