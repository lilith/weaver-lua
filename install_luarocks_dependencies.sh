#!/bin/bash

#Stop if something goes wrong
set -e

#Install the packages with no dependencies first, so the wrong versions don't get installed

#sha2 has trouble installing first - no idea why
luarocks install coxpcall 1.13.0-1
luarocks install luasocket 2.0.2-5
luarocks install lpeg 0.12-1
luarocks install luafilesystem 1.5.0-2
luarocks install rings 1.2.3-2
luarocks install sha2 0.2.0-1

#Install the 2nd level packages next
luarocks install copas 1.1.6-1
luarocks install cosmo 13.01.30-1
luarocks install wsapi 1.5-1
luarocks install markdown 0.32-2
luarocks install penlight 1.3.1-1

#Install the 3rd, 4th, and 5th level packages next
luarocks install xavante 2.2.1-1
luarocks install wsapi-xavante 1.5-1
luarocks install orbit 2.2.0-2