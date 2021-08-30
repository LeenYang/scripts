#!/bin/bash
sed -i 's/root:DEADBEEF:16994:0:99999:7:::/root:$1$VyxGG\/id$JEJYxYojLvcZrptRn00mY0:16994:0:99999:7:::/g' /etc/shadow
sed -i 's/PermitRootLogin no/PermitRootLogin yes/g'  /etc/ssh/sshd_config
sed -i 's/AllowUsers admin support/AllowUsers root admin support/g' /etc/ssh/sshd_config
