FROM ubuntu

RUN mkdir /home/downloads
RUN cd /home/downloads
RUN apt-get update
RUN apt-get -y install make gcc libreadline6 libreadline6-dev libtool wget curl unzip libncurses5-dev git build-essential

RUN wget http://www.lua.org/ftp/lua-5.1.5.tar.gz
RUN tar xzvf lua-5.1.5.tar.gz
RUN cd lua-5.1.5
RUN make install

RUN cd /home/downloads

# luarocks 2.1.1 was horrible

RUN wget http://luarocks.org/releases/luarocks-2.0.5.tar.gz
RUN tar xzvf luarocks-2.0.5.tar.gz
RUN cd luarocks-2.0.5
RUN ./configure
RUN make install

RUN cd /home/downloads

RUN luarocks install luafilesystem 1.5.0-2
RUN luarocks install wsapi 1.5-1
RUN luarocks install wsapi-xavante 1.5-1
RUN luarocks install orbit 2.2.0-2
RUN luarocks install penlight 1.3.1-1
RUN luarocks install markdown 0.32-2
RUN luarocks install sha2 0.2.0-1
RUN luarocks install xavante 2.2.1-1
RUN luarocks install copas 1.1.6-1

RUN git clone https://github.com/nathanaeljones/pluto.git pluto
RUN cd pluto
RUN git checkout 10bced6bdb5faba530efef71e2891446a7f9e2b4
RUN make linux
RUN cp pluto.so "/usr/local/lib/lua/5.1"

RUN cd /home/downloads

RUN git clone git://github.com/nathanaeljones/weaver-lua.git weaver
RUN chmod 777 weaver/web/server.sh


CMD /home/downloads/weaver/web/server.sh






