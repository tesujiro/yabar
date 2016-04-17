#!/bin/bash
YABAR_VERSION="0.1.0"
YABAR_TMPDIR="/tmp/${0##*/}.$$"
mkdir $YABAR_TMPDIR
yabar_case_stdout() { echo $YABAR_TMPDIR/$1/stdout; }
yabar_case_stderr() { echo $YABAR_TMPDIR/$1/stderr; }
yabar_case_mkdir()  { mkdir $YABAR_TMPDIR/$1; }

declare -i YABAR_CURRENT_CASE=0
declare -a YABAR_CASE_NAME
declare -a YABAR_CASE_FUNCTION
declare -a YABAR_CASE_TITLE        # 
declare -a YABAR_CASE_INSPECTION   # inspction number Key: CaseNum
declare -a YABAR_TRACE_FILE        # tracee file Key: CaseNum
declare -A YABAR_TRACE_START_TIME  # Key: CaseNum"_"FileName
declare -A YABAR_TRACE_START_LINE  # Key: CaseNum"_"FileName
declare -A YABAR_INSP_TITLE        # Key: CaseNum"_"InspctionNum
declare -A YABAR_INSP_RESULT       # Key: CaseNum"_"InspctionNum

shopt -s expand_aliases
alias yabar_run='yabar_main "$@"'

YABAR_COMMAND_BUFFER_LENGTH=9
YABAR_COMMAND_BUFFER=()
yabar_debug()
{
  YABAR_COMMAND_BUFFER+=("$BASH_COMMAND")
  if [ ${#YABAR_COMMAND_BUFFER[@]} -gt $YABAR_COMMAND_BUFFER_LENGTH ];then
    YABAR_COMMAND_BUFFER=("${YABAR_COMMAND_BUFFER[@]:1}")
  fi
  YABAR_PREV_COMMAND="${YABAR_COMMAND_BUFFER[1]}"
}
set -T
trap yabar_debug DEBUG

yabar_pallet()
{
  cat << EOF |awk 'sub(/#.*/,"") >=0 && NF>0'
# COLOR
BLACK     [30m        RED       [31m        GREEN     [32m        YELLOW    [33m        
BLUE      [34m        MAGENTA   [35m        CYAN      [36m        WHITE     [37m        
# BACKGROUND COLOR
BK_BLACK     [40m        BK_RED       [41m        BK_GREEN     [42m        BK_YELLOW    [43m        
BK_BLUE      [44m        BK_MAGENTA   [45m        BK_CYAN      [46m        BK_WHITE     [47m        
# CURSOR
MOVE_TOP     [1;1H        CLEAR        [2J        CLEAR_LINE   [0J        
# CHARACTER
ORG       [0m        BOLD      [1m        UNDER     [4m        BLINK     [5m        REVERSE   [7m        
EOF
}
export -f yabar_pallet

yabar_paint()
{
  local COLOR=$1
  local PATTERN="${2:-.*}"
  local NO_NL=${NO_NL:-"NO"}

  awk -v PATTERN=$PATTERN -v COLOR=$COLOR -v NO_NL=$NO_NL '
  BEGIN{ while ( "yabar_pallet" |& getline ) for(i=1;i<=NF;i=i+2)PAL[$i]="\033"$(i+1); }
  {
      gsub(PATTERN,PAL[COLOR] "&" PAL["ORG"]);
      if ( NO_NL=="YES" ){ printf "%s",$0 }
      else { print $0; }
  }
  '
}
yabar_paint_OK() { yabar_paint GREEN; }
yabar_paint_NG() { yabar_paint RED; }

yabar_echo() { [ $QUIET_MODE ] || echo "$@"; }
yabar_cat()  { [ $QUIET_MODE ] || cat $@ ; }

yabar_error()
{
  echo ERROR: $@ 1>&2
  echo ${FUNCNAME[@]} |awk 'BEGIN{OFS=" <-"}{$1="exit";print }' 1>&2
  rm -r $YABAR_TMPDIR
  exit 1
}

yabar_logo()
{
  echo Yet Another BAsh scripts Runner \(Ver.$YABAR_VERSION\)
}

yabar_create_case()
{
  basename `mktemp -d $YABAR_TMPDIR/OXXX`
}

yabar_case_function()
{
  local case=$1
  local case_no=$2
  cat <<EOF
$case.is(){ yabar_case_is $case_no "\$@"; }
$case.start.trace(){ yabar_start_trace $case_no "\$@" ; }
$case.execute(){ yabar_execute $case_no "\$@" ; }
$case.cat.stdout(){ yabar_cat_stdout $case_no "\$@" ; }
$case.cat.stderr(){ yabar_cat_stderr $case_no "\$@" ; }
$case.cat.trace(){ yabar_cat_trace $case_no "\$@" ; }
$case.check(){ yabar_check $case_no \$@ ; }
EOF
}

yabar_case_init()
{
  local case_name=$1
  YABAR_CURRENT_CASE+=1
  YABAR_CASE_NAME+=($case_name)
  YABAR_CASE_INSPECTION[$YABAR_CURRENT_CASE]=0
  YABAR_CASE_FUNCTION[$YABAR_CURRENT_CASE]=${FUNCNAME[1]}
  YABAR_TRACE_FILE=()    #needed ??
  YABAR_TRACE_START_TIME=()    #needed ??
  YABAR_TRACE_START_LINE=()    #needed ??
  eval "`yabar_case_function $case_name $YABAR_CURRENT_CASE`"
}

yabar_display_case_title()
{
  local case_no=$1
  yabar_echo ===============================================================
  yabar_echo $(printf "%2.2d." $case_no) ${YABAR_CASE_FUNCTION[$case_no]} \
             :${YABAR_CASE_TITLE[$case_no]}
  yabar_echo ===============================================================
}

yabar_case_is()
{
  local case_no=$1
  YABAR_CASE_TITLE[$case_no]="${*:2}"
  yabar_display_case_title $case_no
}

yabar_start_trace()
{
  local case_no=$1
  for file in ${@:2} ;do
    local filepath=`readlink -f $file`
    YABAR_TRACE_FILE+=$filepath
    if [ -f $file ];then
      YABAR_TRACE_START_LINE[$case_no"_"$filepath]=`wc -l $filepath|awk '{print $1}'`
    else
      YABAR_TRACE_START_TIME[$case_no"_"$filepath]=`date "+%Y-%m-%d %H:%M:%S.%N"`
    fi
  done
}

yabar_execute()
{
  local case_no=$1
  local command="${@:2}"
  local stdout=`yabar_case_stdout $case_no`
  local stderr=`yabar_case_stderr $case_no`
  yabar_case_mkdir $case_no
  yabar_echo command : "$command"
  yabar_echo "start  :" `date`
  #TODO: time
  trap - DEBUG
  trap 'sed -i -e "s|${BASH_SOURCE[1]}|${BASH_SOURCE[2]}|" -e "s|$LINENO|${BASH_LINENO[1]}|" $stderr ' ERR
  eval "$command" >$stdout 2>$stderr
  exit=$?
  yabar_echo Return Code: $exit
  trap - ERR
  trap yabar_debug DEBUG
  yabar_echo Standard Out:
  [ ! -z $stdout ] && yabar_cat $stdout
  yabar_echo Standard Error:
  [ ! -z $stderr ] && yabar_cat $stderr
  for file in ${YABAR_TRACE_FILE[@]}; do
    yabar_echo TRACE $file:
    yabar_cat_trace $file | yabar_cat
  done
  yabar_echo "finish :" `date`
  return $exit
}

yabar_cat_stdout()
{
  local case_no=$1
  local stdout=`yabar_case_stdout $case_no`
  cat $stdout
}

yabar_cat_stderr()
{
  local case_no=$1
  local stderr=`yabar_case_stderr $case_no`
  cat $stderr
}

yabar_cat_trace()
{
  local case_no=$1
  local touchfile=$YABAR_TMPDIR/touchfile
  for file in ${@:2} ;do
    local filepath=`readlink -f $file`
    if [ -f $file ];then
      local SKIP=${YABAR_TRACE_START_LINE["$case_no"_"$filepath"]}
      awk -v SKIP=$SKIP 'NR>SKIP{print $0}' $file
    else 
      touch -d "${YABAR_TRACE_START_TIME[$case_no"_"$filepath]}" $touchfile
      find $file -type f -newer $touchfile |sort
    fi
  done
}

yabar_check()
{
  local result=$?
  local case_no=$1
  local prev_command="$YABAR_PREV_COMMAND"
  [[ $# -ne 1 ]] && local title="${@:2}" || local title="$prev_command"

  ((YABAR_CASE_INSPECTION[$case_no]++))
  local insp_no=${YABAR_CASE_INSPECTION[$case_no]}

  local insp_index=$case_no"_"$insp_no
  YABAR_INSP_TITLE[$insp_index]="$title"
  [ $result -eq 0 ] && YABAR_INSP_RESULT[$insp_index]="OK" || YABAR_INSP_RESULT[$insp_index]="NG"
  local INSP_TITLE_LENGTH=`echo -n ${YABAR_INSP_TITLE[$insp_index]}|iconv -f UTF-8 -t SJIS|wc -c`
  local DOTS=`printf '.%.0s' $(seq 1 $((50 - $INSP_TITLE_LENGTH)))`
  #local DOTS=`printf '.%.0s' $(seq 1 $((50 - ${#YABAR_INSP_TITLE[$insp_index]})))`
  yabar_echo `printf "%2.2d-%2.2d." $case_no $insp_no `"${YABAR_INSP_TITLE[$insp_index]}"  $DOTS ${YABAR_INSP_RESULT[$insp_index]} \
    | yabar_paint_${YABAR_INSP_RESULT[$insp_index]}
}

yabar_paint_summary_OK()
{
  yabar_paint BLACK |yabar_paint BK_GREEN
}

yabar_paint_summary_NG()
{
  yabar_paint BOLD |yabar_paint BLACK |yabar_paint BK_RED |yabar_paint REVERSE
}

yabar_show_summary()
{
  yabar_echo 
  echo ===============================================================
  echo TEST RESULTS SUMMARY.
  echo ===============================================================
  local count_OK=0
  local count_NG=0
  for case_no in `seq 1 $YABAR_CURRENT_CASE`; do
    echo `printf "%2.2d." $case_no`${YABAR_CASE_FUNCTION[$case_no]} :  ${YABAR_CASE_TITLE[$case_no]} 
    [ ${YABAR_CASE_INSPECTION[$case_no]} -eq 0 ] && echo && continue;
 
    local NO_NL="YES"
    for i in `seq 1 ${YABAR_CASE_INSPECTION[$case_no]}`; do
      if [ "${YABAR_INSP_RESULT[$case_no"_"$i]}" == "OK" ]; then
        printf "%2.2d" $i |yabar_paint_summary_OK
        ((count_OK++))
      else
        printf "%2.2d" $i |yabar_paint_summary_NG
        ((count_NG++))
      fi
      printf " " 
    done
    echo
    local NO_NL="NO"
    for i in `seq 1 ${YABAR_CASE_INSPECTION[$case_no]}`; do
      if [ "${YABAR_INSP_RESULT[$case_no"_"$i]}" != "OK" ]; then
        printf "=>%2.2d %s\n" $i "${YABAR_INSP_TITLE[$case_no"_"$i]}" |yabar_paint_summary_NG
      fi
    done
  done
  echo total $(($count_OK + $count_NG)) inspections, $count_NG failures.
  [ $count_NG -ne 0 ] && exit 1 || exit 0
}

yabar_main()
{
  yabar_logo
  while getopts wWqQ OPT ;do
    case ${OPT,,} in
      "w" ) WHITE_MODE="TRUE" ;;
      "q" ) QUIET_MODE="TRUE" ;;
        * ) echo "Usage: ${0##*/} [-w] [-q] [TEST_CASE]*" 1>&2
            exit 1 ;;
    esac
  done
  # オプション部分を切り捨てる。
  shift `expr $OPTIND - 1`

  if [ $# -eq 0 ];then
    local TEST_FUNCS=`declare -F |awk '{print $3}' |grep ^test_ `
  else
    # TODO: add function name matching
    local TEST_FUNCS="$*"
  fi

  # BEGIN 関数があれば実行
  [ `declare -F begin| wc -l` -eq 1 ] && begin

  # TEST 関数の実行
  for FUNC in $TEST_FUNCS ;do
    eval $FUNC
  done
  # END 関数があれば実行
  [ `declare -F end| wc -l` -eq 1 ] && end
  yabar_show_summary

  rm -r $YABAR_TMPDIR
}

