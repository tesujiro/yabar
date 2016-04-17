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

## Install

## Contribution

## Licence

[MIT]

## Author

[tesujiro](https://github.com/tesujiro)

