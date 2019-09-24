#!/usr/bin/env bash

set -e

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Warning: tests designed to work on OSX (BSD), can fail on GNU"
fi

function assert_size
{
    if [[ $# != 2 ]]; then echo "Must have 2 arguments"; exit 1; fi
    f=$1
    size="$(stat -f%z "$f")"
    expected="$2"
    if [[ "$size" != "$expected" ]]; then echo "Assertion failed: size of \"$f\" expected $expected, got $size"; exit 2; fi
}

function assert_equal
{
    if [[ $# != 2 ]]; then echo "Must have 2 arguments"; exit 1; fi
    if [[ "$1" != "$2" ]]; then echo "Assertion failed: should be equal, got '$1' and '$2'"; exit 2; fi
}

function assert_not_equal
{
    if [[ $# != 2 ]]; then echo "Must have 2 arguments"; exit 1; fi
    if [[ "$1" == "$2" ]]; then echo "Assertion failed: should be equal, got '$1' and '$2'"; exit 2; fi
}

function assert_result
{
    if [[ $# < 2 ]]; then echo "Must have at least 2 arguments"; exit 1; fi
    code="$1"
    shift
    set +e
    eval "$@" >/dev/null 2>&1
    ret=$?
    set -e
    if [[ "$code" != "$ret" ]]; then echo "Assertion failed: expected exit code $code, got $ret while executing $@"; exit 2; fi
}

trap "rm -f unit-test-test.txt unit-test-output.txt" EXIT

echo "Test 1: add bom with replace"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
assert_size unit-test-test.txt 27

assert_result 0 ./addbom unit-test-test.txt
assert_size unit-test-test.txt 30

echo "Test 2: add bom with replace fails on already converted file"
assert_result 2 ./addbom unit-test-test.txt
assert_size unit-test-test.txt 30

echo "Test 3: add bom with output"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
assert_size unit-test-test.txt 27

assert_result 0 ./addbom unit-test-test.txt unit-test-output.txt
assert_size unit-test-test.txt 27
assert_size unit-test-output.txt 30

echo "Test 4: add bom with output fails when file already converted"
assert_result 3 ./addbom unit-test-test.txt unit-test-output.txt
assert_size unit-test-test.txt 27
assert_size unit-test-output.txt 30

echo "Test 5: add bom with output fails when output file already exists"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
assert_result 3 ./addbom unit-test-test.txt unit-test-output.txt

echo "Test 6: doesn't change timestamp when no change is needed inline"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
assert_result 0 ./addbom unit-test-test.txt
timestamp_before="$(stat -f%m "unit-test-test.txt")"
sleep 2
assert_result 2 ./addbom unit-test-test.txt
timestamp_after="$(stat -f%m "unit-test-test.txt")"
assert_equal "$timestamp_before" "$timestamp_after"

echo "Test 7: doesn't change timestamp when no change is needed with replace"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
rm "unit-test-output.txt"
assert_result 0 ./addbom unit-test-test.txt unit-test-output.txt
timestamp_before="$(stat -f%m "unit-test-output.txt")"
sleep 2
assert_result 3 ./addbom unit-test-test.txt unit-test-output.txt
timestamp_after="$(stat -f%m "unit-test-output.txt")"
assert_equal "$timestamp_before" "$timestamp_after"

echo "Test 8: timestamp change test works"
echo "Zażółć gęślą jaźń" > unit-test-test.txt
timestamp_before="$(stat -f%m "unit-test-test.txt")"
sleep 2
touch "unit-test-test.txt"
timestamp_after="$(stat -f%m "unit-test-test.txt")"
assert_not_equal "$timestamp_before" "$timestamp_after"

echo "All tests passed"