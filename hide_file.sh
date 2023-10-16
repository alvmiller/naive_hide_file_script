#!/bin/bash

# <<<------------------------------------------------------------------------------------------->>>|
# <<<-------------------------------------- Variables ------------------------------------------>>>|
# <<<------------------------------------------------------------------------------------------->>>|

#./hide_file.sh 1.txt 1.bin 1
#./hide_file.sh 1.bin 2.txt 2

#./hide_file.sh 1.txt 1.bin 1 d
#./hide_file.sh 1.bin 2.txt 2 d

readonly NC='\033[0m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly BLUEBOLD='\033[1;34m'

readonly tmp_dir="_out_tmp_dir_/"
readonly arch_enc_str="$tmp_dir""arch_enc.aeb"
readonly enc_str="$tmp_dir""enc.eb"
readonly dec_str="$tmp_dir""arch_enc.aeb"
readonly rand_head_str="$tmp_dir""head_file"
readonly rand_tail_str="$tmp_dir""tail_file"
readonly rand_parts=3
readonly split_file_str="$tmp_dir""xab"
readonly enc_mode=1
readonly dec_mode=2
readonly def_pwd_mode='d'

pwd_mode=0
arch_enc_res=""
unarch_enc_res=""
in_file_checksum=""
out_file_checksum=""
run_start=0
run_end=0
run_diff=0
in_file_size=0
out_file_size=0
prepared_file_size=0
tmp_file_size=0
file_in_name_str=""
file_out_name_str=""
mode_cmd=0
cmd_res=1
func_result=1
tmp_val=1
result=1

# <<<------------------------------------------------------------------------------------------->>>|
# <<<------------------------------------  Functions   ----------------------------------------->>>|
# <<<------------------------------------------------------------------------------------------->>>|

function echo_warning()
{
    echo -e "${YELLOW}WARNING${NC}: $1"
}

function echo_error()
{
    echo -e "\t${RED}ERROR${NC}:\n\t$1"
}

function print_help()
{
    echo
    echo -e "\tHelp information (how to)"
    echo
    echo -e "${GREEN}USAGE${NC}:"
    echo -e "\t${0} [options]"
    echo
    echo -e "${GREEN}OPTIONS${NC}:"
    echo -e "\t--help"
    echo -e "\tPrint this message"
    echo
    echo "Run:"
    echo -e "\t$0"
    echo -e "\t'input file name' 'output file name' 'mode type (1 - hide, 2 - unhide)' " \
            "'default password' (d - optional)"
}

function print_fail_and_exit1()
{
    echo
    echo -e "${BLUE}Run status${NC}:\n\t${RED}Failed${NC}"
    exit 1
}

function cleanup_interrupted_script()
{
    echo
    echo_error "Script interrupted!"
    print_fail_and_exit1
}

function registrate_exception_and_trap()
{
    set -e

    trap cleanup_interrupted_script SIGINT
    trap cleanup_interrupted_script SIGTERM
    trap cleanup_interrupted_script SIGHUP
    trap cleanup_interrupted_script SIGQUIT
    trap cleanup_interrupted_script ERR
}

function print_current_step()
{
    echo
    echo "> ""$1"
}

# <<<------------------------------------------------------------------------------------------->>>|

function func_hide()
{
    # <<<--------------------------------------------------------------------------------------->>>|

    print_current_step "Archive with encryption"
    if [ "$pwd_mode" = 1 ]; then
        arch_enc_res=$(7z a -mhe=on -ms=on -mx=9 "$arch_enc_str" "$file_in_name_str" -p123)
    else
        arch_enc_res=$(7z a -mhe=on -ms=on -mx=9 "$arch_enc_str" "$file_in_name_str" -p)
    fi
    tmp_file_size=$(stat -c %s "$arch_enc_str")
    echo "Archived and Encrypted File: $arch_enc_str ($tmp_file_size)"

    # <<<--------------------------------------------------------------------------------------->>>|

    print_current_step "Encryption"
    if [ "$pwd_mode" = 1 ]; then
        cmd_res=$(openssl enc -aes-256-cbc -pbkdf2 -in "$arch_enc_str" -out "$enc_str" -pass pass:123)
    else
        cmd_res=$(openssl enc -aes-256-cbc -pbkdf2 -in "$arch_enc_str" -out "$enc_str")
    fi
    
    prepared_file_size=$(stat -c %s "$enc_str")
    echo "Archived and Encrypted File: $enc_str ($prepared_file_size)"

    # <<<--------------------------------------------------------------------------------------->>>|

    print_current_step "Random files"
    cmd_res=$(head -c "$prepared_file_size" < /dev/urandom > "$rand_head_str")
    tmp_file_size=$(stat -c %s "$rand_head_str")
    echo "Head random file: $rand_head_str ($tmp_file_size)"
    cmd_res=$(head -c "$prepared_file_size" < /dev/urandom > "$rand_tail_str")
    tmp_file_size=$(stat -c %s "$rand_tail_str")
    echo "Head random file: $rand_tail_str ($tmp_file_size)"

    # <<<--------------------------------------------------------------------------------------->>>|

    print_current_step "Steganography"
    cmd_res=$(cat "$rand_head_str" "$enc_str" "$rand_tail_str" > "$file_out_name_str")
    out_file_size=$(stat -c %s "$file_out_name_str")
    echo "Out file: $file_out_name_str ($out_file_size)"
    
    # <<<--------------------------------------------------------------------------------------->>>|

    return 0
}

function func_unhide()
{
    # <<<--------------------------------------------------------------------------------------->>>|

    print_current_step "Steganography"
    tmp_file_size=$(("$in_file_size" / "$rand_parts"))
    cmd_res=$(split -b "$tmp_file_size" "$file_in_name_str" "$tmp_dir""x")
    tmp_file_size=$(stat -c %s "$split_file_str")
    echo "Count of parts: $rand_parts"
    echo "Part: $split_file_str ($tmp_file_size)"
    
    # <<<--------------------------------------------------------------------------------------->>>|
    
    print_current_step "Decryption"
    if [ "$pwd_mode" = 1 ]; then
        cmd_res=$(openssl enc -d -aes-256-cbc -pbkdf2 -in "$split_file_str" -out "$dec_str" -pass pass:123)
    else
        cmd_res=$(openssl enc -d -aes-256-cbc -pbkdf2 -in "$split_file_str" -out "$dec_str")
    fi
    
    prepared_file_size=$(stat -c %s "$dec_str")
    echo "Archived and Encrypted File: $dec_str ($prepared_file_size)"
    
    # <<<--------------------------------------------------------------------------------------->>>|
    
    print_current_step "Unarchive with encryption"
    if [ "$pwd_mode" = 1 ]; then
        unarch_enc_res=$(exec 7z x "$dec_str" -p123)
    else
        exec 7z x "$dec_str"
    fi
    
    # <<<--------------------------------------------------------------------------------------->>>|
    # <<<--------------------------------------------------------------------------------------->>>|
    # <<<--------------------------------------------------------------------------------------->>>|
    
    return 0
}

# <<<------------------------------------------------------------------------------------------->>>|s

# <<<------------------------------------------------------------------------------------------->>>|
# <<<---------------------------  Exception trap registration  --------------------------------->>>|
# <<<----------------------------------  (optional)  ------------------------------------------->>>|
# <<<------------------------------------------------------------------------------------------->>>|

registrate_exception_and_trap

# <<<------------------------------------------------------------------------------------------->>>|
# <<<--------------------------------------   Run   -------------------------------------------->>>|
# <<<------------------------------------------------------------------------------------------->>>|

#reset
clear
echo
echo
echo "-------------------------------------------------------------------------"
echo -e "\t\t\t${BLUEBOLD}Hide file tool${NC}"
echo "-------------------------------------------------------------------------"
echo

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Check input parameters"

if [ $# -eq 0 ]; then
    echo_error "No parameters, use '--help' for info"
    print_fail_and_exit1
fi
if [ $# -eq 1 ]; then
    while [ -n "$1" ]; do
        echo "Used parameter $1"
        case $1 in
        --help)
            print_help
            echo
            exit 2
            ;;
        *)
            echo_error "Undefined/Bad parameter: '$1', use '--help'"
            print_fail_and_exit1
            ;;
        esac
        shift
    done
fi

if [ $# -eq 2 ]; then
    if [ "$2" = "$dec_mode" ]; then
        file_in_name_str=$1
        mode_cmd=$2
    else
        echo_error "Undefined/Bad parameter: '$2', use '--help'"
        print_fail_and_exit1
    fi
else
    if [ $# -eq 3 ]; then
        if [[ "$3" = "$enc_mode" || "$3" = "$def_pwd_mode" ]]; then
            if [ "$3" = "$enc_mode" ]; then
                file_in_name_str=$1
                file_out_name_str=$2
                mode_cmd=$3
            else
                file_in_name_str=$1
                mode_cmd=$2
                pwd_mode=1
            fi
        else
           echo_error "Undefined/Bad parameter: '$3', use '--help'"
           print_fail_and_exit1
        fi
    else
        if [ $# -eq 4 ]; then
            if [ "$3" = "$enc_mode" ]; then
                if [ "$4" = "$def_pwd_mode" ]; then
                    file_in_name_str=$1
                    file_out_name_str=$2
                    mode_cmd=$3
                    pwd_mode=1
                else
                    echo_error "Undefined/Bad parameter: '$4', use '--help'"
                    print_fail_and_exit1
                fi
            else
               echo_error "Undefined/Bad parameter: '$3', use '--help'"
               print_fail_and_exit1
            fi
        else
            echo_error "No or Undefined/Bad parameters, use '--help'"
            print_fail_and_exit1
        fi
    fi
fi

if [ "$mode_cmd" = "$dec_mode" ]; then
    if [ -d "$file_in_name_str" ]; then
        echo_error "Bad type of file!"
        print_fail_and_exit1
    fi
    if [ -f "$file_in_name_str" ]; then
        echo "'$file_in_name_str' is a file"
    else
        echo_error "No Input file ('$file_in_name_str')!"
        print_fail_and_exit1
    fi

    tmp_file_size=$(stat -c %s "$file_in_name_str")
    tmp_val=$(("$tmp_file_size" % "$rand_parts"))
    if [ "$tmp_val" -ne 0 ]; then
        echo_error "Bad input file size ($tmp_file_size)"
        print_fail_and_exit1
    fi
fi

if [ "$mode_cmd" = "$enc_mode" ]; then
    if [ "$file_in_name_str" = "$file_out_name_str" ]; then
        echo_error "Equal parameters (Input/Output)!"
        print_fail_and_exit1
    fi
    
    if [ -d "$file_in_name_str" ]; then
        echo_error "Bad type of file!"
        print_fail_and_exit1
    fi
    if [ -f "$file_in_name_str" ]; then
        echo "'$file_in_name_str' is a file"
    else
        echo_error "No Input file ('$file_in_name_str')!"
        print_fail_and_exit1
    fi
    
    if [ -d "$file_out_name_str" ]; then
        echo_error "Output ('$file_out_name_str') is a directory!"
        print_fail_and_exit1
    fi
    if [ -f "$file_out_name_str" ]; then
        echo_error "Output ('$file_out_name_str) is a file!"
        print_fail_and_exit1
    fi
fi

echo "Parameters checked"

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Input parameters (use input variables)"
echo "Input 'file_in_name_str' parameter value: $file_in_name_str"
echo "Input 'file_out_name_str' parameter value: $file_out_name_str"
echo "Input 'mode_cmd' parameter value: $mode_cmd"
echo "Input 'pwd_mode' parameter value: $pwd_mode"

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Get start time label"
run_start=$(date +%s)
echo "Start time label: $run_start"

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Input File size"
in_file_size=$(stat -c %s "$file_in_name_str")
echo "Input File size: $in_file_size"

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Temporary out dir"
cmd_res=$(mkdir -p "$tmp_dir")
echo "Tmp out dir: $tmp_dir"

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Checksum In"
echo "File: $file_in_name_str"
in_file_checksum=$(cksum "$file_in_name_str")
echo "$in_file_checksum"

# <<<------------------------------------------------------------------------------------------->>>|

if [ "$mode_cmd" = "$enc_mode" ]; then
    print_current_step "[Hide file]"
    func_hide
    echo
    echo "Result : $?"
fi
if [ "$mode_cmd" = "$dec_mode" ]; then
    print_current_step "[Unhide file]"
    func_unhide
    echo
    echo "Result : $?"
fi

# <<<------------------------------------------------------------------------------------------->>>|

if [ "$mode_cmd" = "$enc_mode" ]; then
    print_current_step "Checksum Out"
    echo "File Out: $file_out_name_str"
    out_file_checksum=$(cksum "$file_out_name_str")
    echo "$out_file_checksum"
fi

# <<<------------------------------------------------------------------------------------------->>>|

print_current_step "Get end time label"
run_end=$(date +%s)
echo "End time label: $run_end"
run_diff=$((run_end - run_start))
echo "Run took $run_diff seconds"

# <<<------------------------------------------------------------------------------------------->>>|

result=0

# <<<------------------------------------------------------------------------------------------->>>|

if [ "$result" -eq 0 ]; then
    echo
    echo -e "${BLUE}Run status${NC}:\n\t${GREEN}Passed${NC} (OK/Succeeded)"
    echo
    exit 0
fi
print_fail_and_exit1

# <<<------------------------------------------------------------------------------------------->>>|
