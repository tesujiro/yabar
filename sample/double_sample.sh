#!/bin/bash

. ../lib/yabar.sh

test_scenario_01()
{
    local case1=`yabar_create_case`; yabar_case_init $case1
    local case2=`yabar_create_case`; yabar_case_init $case2
    $case1.is "the sender case."
    $case2.is "the receiver case."

    $case1.run "echo aaa"
    [ $? -eq 0 ]; $case1.check 
    [ `$case1.cat.stdout |grep "^aaa$" ` ]; $case1.check
    [ ! `$case1.cat.stderr` ]; $case1.check

    $case2.run "echo bbb"
    [ $? -eq 0 ]; $case2.check 
    [ `$case2.cat.stdout |grep "^bbb$" ` ]; $case2.check
    [ ! `$case2.cat.stderr` ]; $case2.check
}

yabarun 

