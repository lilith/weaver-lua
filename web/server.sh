#!/bin/bash

#Run as a background script
if [ "x$1" != "x--" ]; then
#$0 -- 1> ~/server.out.log 2> ~/server.err.log &
$0 -- &
exit 0
fi

#Loop so we can kill it to reload the site

while true 
do 
sudo /usr/local/bin/orbit -p 80 weaver.lua 
done