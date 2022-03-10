FROM ubuntu:20.04 
RUN apt-get update -y 
RUN apt-get install -y sudo python2 python-psutil curl net-tools
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python2 get-pip.py
RUN pip install iptools dxlclient dxlbootstrap dxlfiletransferclient
COPY mnt /mnt
RUN ln -s /mnt/spirent/ccpu/ /usr/spirent & ln -s /usr/bin/python2.7 /usr/local/sbin/python & mkdir -p /swat/log/
COPY xdp-loader /mnt/spirent/ccpu/bin/
COPY libelf.so /usr/lib/x86_64-linux-gnu/libelf.so.1
COPY xdp_xsk.o /mnt/spirent/ccpu/bin
WORKDIR /mnt/spirent/ccpu/bin
cmd ["/bin/bash"]

