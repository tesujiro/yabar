Yabar: Yet Another BAsh scripts Runner.
====

A simple testing framework for bash scripts.

## Description

## Demo
demo  
![Demo](https://raw.githubusercontent.com/tesujiro/yabar/master/img/yabar_demo.gif)  
simple demo  
![Simple Demo](https://raw.githubusercontent.com/tesujiro/yabar/master/img/yabar_demo_simple.gif)

## VS. 

## Requirement

## Usage
    #!/bin/bash
    . ../lib/yabar.sh
    test_01()
    {
        local case=`yabar_create_case`; yabar_case_init $case
        $case.is "The normal case."
        $case.run "echo aaa"
        [ $? -eq 0 ]; $case.check
        [ `$case.cat.stdout |grep "^aaa$" ` ]; $case.check
        [ ! `$case.cat.stderr` ]; $case.check
    }
    yabarun
1.source yabar.sh  
2.make test function named "test_*"  
3.yabarun  
4.create case with "yabar_create_case"  
5.initialize the case  
6.set a title of the case with $case.is function  
7.run command with $case.run  
8.chek the result with $case.check  

    !/bin/bash
    . ../lib/yabar.sh
    test_02()
    {
        local TEMP=/tmp/aaa.txt
        echo xxx >>$TEMP
        date >>$TEMP
    
        local case=`yabar_create_case`; yabar_case_init $case
        $case.is "正常系：既存ファイル追加出力 echoコマンド"
        $case.start.trace $TEMP
        $case.run "echo aaa >>$TEMP"
    
        [ `$case.cat.trace $TEMP |grep "aaa" |wc -l ` -gt 0 ]
        $case.check "File output contains echo string"
        [ `$case.cat.trace $TEMP |grep "xxx" |wc -l ` -eq 0 ]
        $case.check "File output does not contain init string"
        rm $TEMP
    }
    yabarun

1.start trace file with $case.start.trace
2.output trace file with $case.cat.trace

## Install
No installation, download yabar.sh

## Contribution

## Licence

[MIT]

## Author

[tesujiro](https://github.com/tesujiro)

