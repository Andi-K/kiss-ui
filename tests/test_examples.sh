#!/bin/sh

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}" >>$log_file
    
    cat $log_file
    # exit with the right error code.
    exit ${1}
  fi
}

### set Defaults ###

# Default time in secounds to automatical close a KISS-UI.
AUTOCLOSE=2

# example=button_test
# example=show_image

frame=""
no_ss=false

tmp_path="/tmp/KISS-UI/"
img_path="local_ss/"
log_path="log/"

### parse command line options ###

usage="
to build and run all KISS-UI examples:
$(basename "$0") -n \"*\"

compare the screen shots of all examples ending with '_test' 
$(basename "$0") [Options] \"*_test\"

Its likely you can't use the offical screen shots as you use a differnt GTK Theme and Fonts.
Therefore we use and save new screen shots in
\"$PWD/$img_path\" without frames.

Log dir: \"$PWD/$log_path\".

Options:
    -h   show this help text
    -t n time in secounds to automatical close a KISS-UI (default: $AUTOCLOSE)
    -n   no screen shots, only build and run
    -f   include window frames
    -o   use offical screen shots (olny usefull with -f)
"

while getopts 'ht:ofn' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    t) AUTOCLOSE=$OPTARG
       ;;
    o) img_path="../screenshots/GTK+/"
       ;;
    f) frame=" -frame"
       ;;
    n) no_ss=true
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

if [[ -z $1 ]]
then
    echo "$usage" >&2
   exit 1
fi

examples="../examples/$1.rs"
log_file="$log_path$(date +%F_%H-%M-%S)"
div=0

### main script starts here ###

KISSUI_AUTOCLOSE=$AUTOCLOSE export KISSUI_AUTOCLOSE

if [ ! -d $tmp_path ]
then
    mkdir $tmp_path
fi
# mkdir $img_path

for example in $(ls $examples)
do
    example=$(basename -s .rs $example)
    echo "Testing '$example'.rs:" >>$log_file
    
    cargo build --example $example 2>>$log_file
    check_errs $? "cargo build returned an error!"

    if $no_ss
    then
        cargo run --example $example 2>>$log_file
        check_errs $? "cargo run returned an error!"
    else
        ( cargo run --example $example 2>>$log_file; check_errs $? "cargo run returned an error!" ) &
        sleep 1
        ## Get the process ID
        PID=$(ps -e | grep -w $example | awk '{print $1}')
        if [[ -z $PID ]]
        then
            check_errs 3 "can't get process ID
                if the example not paniced we need to change the sleep time"
        fi
        ## Get the window ID
        WID=$(wmctrl -p -l | grep -w $PID | awk '{print $1}')
        # echo $WID

        import $frame -window $WID $tmp_path$example.png 2>>$log_file
        check_errs $? "import returned an error!"

        # display $tmp_path$example.png &

        if [ -f $img_path$example.png ]
        then
            if [ $(identify -quiet -format "%#" $tmp_path$example.png) \
              == $(identify -quiet -format "%#" $img_path$example.png) ]
            then
                echo "OK" >>$log_file
            else
                let "div+=1"
                echo "Warning: divergent screen shot!" >>$log_file
                
                # make sure both images have the same size
                composite $tmp_path$example.png $img_path$example.png \
                tmp_path$example.png

                compare $img_path$example.png $tmp_path$example.png \
                  $log_file"_"$example.png
                  
                if [ $? -gt 1 ]
                then
                    check_errs 2 "can't compare the screen shots"
                fi
            #    display $tmp_path$example_div.png &
            fi
        else
            echo "new screen shot '$img_path$example.png'" >>$log_file
            cp $tmp_path$example.png $img_path$example.png 2>>$log_file
        fi
#        rm $tmp_path$example.png
        wait # until cargo run finish
    fi # $no_ss
done

if [ $div -gt 0 ]
then
    echo "Warning: found $div divergent screen shots"
    let "div+=10"
    exit $div
fi