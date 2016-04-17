#!/bin/bash

. ../lib/yabar.sh

test_normal()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "The normal case."
    $case.run "echo aaa"
    [ $? -eq 0 ]; $case.check 
    [ `$case.cat.stdout |grep "^aaa$" ` ]; $case.check
    [ ! `$case.cat.stderr` ]; $case.check
}

test_error()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "The error case."
    $case.run "aaa aaa"
    [ $? -ne 0 ]; $case.check
    [ ! `$case.cat.stdout` ]; $case.check
    [ "`$case.cat.stderr | grep "not found"`" ]; $case.check
}

yabarun 

