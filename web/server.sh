#!/bin/bash

#Run as a background script
if [ "x$1" != "x--" ]; then
#$0 -- 1> ~/server.out.log 2> ~/server.err.log &
$0 -- &
exit 0
fi

#Loop so we can kill it to reload the site

DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

while true 
do 
# TODO, should break out of loop if error != 0
sudo /usr/local/bin/orbit -p 80 weaver.lua 
done