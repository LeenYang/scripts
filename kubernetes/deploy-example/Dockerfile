FROM ubuntu:20.04
RUN apt-get update 
RUN apt-get install -y sudo net-tools openssh-server
RUN mkdir -p /mnt/spirent/ccpu/bin/
RUN mkdir -p /mnt/spirent/ccpu/lib/python
RUN mkdir -p /swat/log
RUN mkdir -p /mnt/vm/
COPY ./S99spirent /etc/rc3.d/S99spirent
RUN useradd -ms /bin/bash lyang
RUN echo "lyang:welcome" | chpasswd
ENTRYPOINT service ssh restart && bash
