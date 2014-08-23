FROM ubuntu:12.04

MAINTAINER Andy Sykes <github@tinycat.co.uk>

RUN apt-get -y update
RUN apt-get -y install nmap

EXPOSE 12345/tcp

CMD ["ncat", "-l", "12345", "-k", "-c", "xargs -n1 echo"]