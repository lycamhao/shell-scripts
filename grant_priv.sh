#!/bin/sh

if [ ! -z $1 ]; then
    tabList=`cat $1`
else
    echo "Please give me a list of table"
fi 