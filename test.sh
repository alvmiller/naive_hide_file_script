#!/bin/bash

readonly raw_data_file="1.txt"
readonly raw_data="123.txt"
readonly bin_data_file="1.bin"
readonly tmp_dir="_out_tmp_dir_/"
#readonly sleep_time=10

test_result=1

#reset
#clear

#echo 123 > 1.txt
echo "$raw_data" > "$raw_data_file"

#./hide_file.sh 1.txt 1.bin 1 d > /dev/null
./hide_file.sh "$raw_data_file" "$bin_data_file" 1 d
test_result=$?
#sleep "$sleep_time"
rm "$raw_data_file"
rm -rf "$tmp_dir"
if [ "$test_result" -ne 0 ]; then
    echo TestEnc:Failed
    exit 1
fi

#./hide_file.sh 1.bin 2 d > /dev/null
./hide_file.sh "$bin_data_file" 2 d
test_result=$?
echo DATAFILE
cat "$raw_data_file"
#sleep "$sleep_time"
rm "$bin_data_file"
rm "$raw_data_file"
rm -rf "$tmp_dir"
if [ "$test_result" -ne 0 ]; then
    echo TestDec:Failed
    exit 1
fi

echo Test:Passed
exit 0
