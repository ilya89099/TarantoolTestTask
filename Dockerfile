FROM tarantool/tarantool:2.6.0

COPY *.lua /opt/tarantool/
EXPOSE 80
WORKDIR /opt/tarantool

CMD ["tarantool", "server.lua"]

