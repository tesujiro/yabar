#!/bin/bash

. ../lib/yabar.sh

#shopt -s expand_aliases

begin()
{
   echo テストフレームワークのテスト
}

end()
{
:
}

test_normal_01()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "正常系：標準出力 echoコマンド"
    $case.run 'echo "aaa    bbb"'

    [ $? -eq 0 ]
    $case.check 

    [ `$case.cat.stdout |grep "aaa" |wc -l ` -eq 1 ]
    $case.check
    [ `$case.cat.stdout |grep 'aaa    bbb' |wc -l ` -eq 1 ]
    $case.check

    [ `$case.cat.stderr |wc -l ` -eq 0 ]
    $case.check
}

test_normal_02()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "正常系：新規ファイル出力 echoコマンド"
    local TEMP=/tmp/aaa.txt
    $case.start.trace $TEMP

    $case.run "echo aaa >$TEMP"

    [ $? -eq 0 ]
    $case.check "Return Code"

    [ ! `$case.cat.stdout |grep "aaa"` ]
    $case.check "Standard Output"

    [[ ! `$case.cat.stderr` ]]
    $case.check "Standard Error"

    [ `$case.cat.trace $TEMP |grep "aaa" |wc -l ` -gt 0 ]
    $case.check "File Output"

    rm $TEMP
}

test_normal_03()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "正常系：既存ファイル追加出力 echoコマンド"
    local TEMP=/tmp/aaa.txt
    echo xxx >>$TEMP
    date >>$TEMP
    $case.start.trace $TEMP

    $case.run "echo aaa >>$TEMP"

    [ $? -eq 0 ]
    $case.check "Return Code"

    [ `$case.cat.stdout |grep "aaa" |wc -l ` -eq 0 ]
    $case.check "Standard Output"

    [ `$case.cat.stderr |wc -l ` -eq 0 ]
    $case.check "Standard Error"

    [ `$case.cat.trace $TEMP |grep "aaa" |wc -l ` -gt 0 ]
    $case.check "File Output contains echo string"

    [ `$case.cat.trace $TEMP |grep "xxx" |wc -l ` -eq 0 ]
    $case.check "File Output does notcontain init string"

    rm $TEMP
}

test_normal_04()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "正常系：ディレクトリ監視 ファイル作成"
    local TEMP=/tmp
    local TEMPFILE=/tmp/aaa.txt
    $case.start.trace $TEMP

    $case.run "echo aaa >>$TEMPFILE"

    [ $? -eq 0 ]
    $case.check "Return Code"

    [ `$case.cat.stdout |grep "aaa" |wc -l ` -eq 0 ]
    $case.check "Standard Output"

    [ `$case.cat.stderr |wc -l ` -eq 0 ]
    $case.check "Standard Error"

    [ `$case.cat.trace $TEMP |grep "aaa.txt" |wc -l ` -gt 0 ]
    $case.check "File Output Dir contain created file"

    rm $TEMPFILE
}

test_normal_05()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "正常系：ディレクトリ監視 ファイル更新"
    local TEMP=/tmp
    local TEMPFILE=/tmp/aaa.txt
    date >>$TEMPFILE
    echo xxx >>$TEMPFILE
    $case.start.trace $TEMP

    $case.run "echo aaa >>$TEMPFILE"

    [ $? -eq 0 ]
    $case.check "Return Code"

    [ `$case.cat.stdout |grep "aaa" |wc -l ` -eq 0 ]
    $case.check "Standard Output"

    [ `$case.cat.stderr |wc -l ` -eq 0 ]
    $case.check "Standard Error"

    [ `$case.cat.trace $TEMP |grep "aaa.txt" |wc -l ` -gt 0 ]
    $case.check "File Output Dir contain updated file"

    rm $TEMPFILE
}

test_error_01()
{
    local case=`yabar_create_case`; yabar_case_init $case
    $case.is "異常系：標準エラー出力 Command not found"
    $case.run "aaa aaa"

    [ $? -ne 0 ]
    $case.check "リターン値がゼロでない"

    [ `$case.cat.stdout |wc -l ` -eq 0 ]
    $case.check "標準出力なし"

    [ `$case.cat.stderr | grep "not found"|wc -l ` -ne 0 ]
    $case.check "標準エラー出力メッセージ確認"

}

yabarun

