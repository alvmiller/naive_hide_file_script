#!/bin/bash

test_result=1

reset

echo 123 > 1.txt

#./hide_file.sh 1.txt 1.bin 1 d > /dev/null
./hide_file.sh 1.txt 1.bin 1 d
test_result=$?
#sleep 10
rm 1.txt
rm -rf _out_tmp_dir_/
if [ "$test_result" -ne 0 ]; then
    echo Test:Failed
    exit 1
fi

#./hide_file.sh 1.bin 2 d > /dev/null
./hide_file.sh 1.bin 2 d
test_result=$?
#sleep 10
rm 1.bin
rm 1.txt
rm -rf _out_tmp_dir_/
if [ "$test_result" -ne 0 ]; then
    echo Test:Failed
    exit 1
fi

echo Test:Passed
exit 0
