FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y build-essential gdb
RUN echo 'set auto-load safe-path /app' > /root/.gdbinit

VOLUME /app
CMD [ "echo", "ubuntu 20.04 launched." ]
