FROM tarantool/tarantool:2.6.0
MAINTAINER doc@tarantool.org

COPY *.lua /opt/tarantool/
EXPOSE 3301
WORKDIR /opt/tarantool

CMD ["tarantool", "server.lua"]
