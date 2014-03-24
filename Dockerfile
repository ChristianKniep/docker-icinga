###### LEK (Logstash/Elasticsearch/Kibana3)
# A docker image that includes
# - logstash (1.4)
# - elasticsearch (1.0)
# - kibana (3.0)
FROM qnib/docker-fd20
MAINTAINER "Christian Kniep <christian@qnib.org>"


RUN yum install -y openssh-server 
RUN sshd-keygen

# Install dependencies
RUN yum install -y gcc glibc glibc-common gd gd-devel libjpeg libjpeg-devel libpng libpng-devel net-snmp net-snmp-devel net-snmp-utils

RUN /usr/sbin/useradd -m icinga 
RUN echo "icinga:icinga" |chpasswd
#RUN /usr/sbin/groupadd icinga
RUN /usr/sbin/groupadd icinga-cmd
RUN /usr/sbin/usermod -a -G icinga-cmd icinga

# Install httpd
RUN yum install -y httpd
RUN /usr/sbin/usermod -a -G icinga-cmd apache

# compile icinga
WORKDIR /usr/src
RUN wget -q https://github.com/Icinga/icinga-core/releases/download/v1.11.0/icinga-1.11.0.tar.gz
RUN tar xf icinga-1.11.0.tar.gz
WORKDIR /usr/src/icinga-1.11.0
RUN ./configure --with-command-group=icinga-cmd --disable-idoutils
RUN make all
# config
RUN make all
RUN make fullinstall
RUN make install-config
# classic web
RUN make cgis
RUN make install-cgis
RUN make install-html

# apache2
RUN make install-webconf
RUN htpasswd -b -c /usr/local/icinga/etc/htpasswd.users icingaadmin icinga

# Set (very simple) password for root
RUN echo "root:root"|chpasswd

# nagios-plugins
WORKDIR /usr/src
RUN wget -q http://www.nagios-plugins.org/download/nagios-plugins-2.0.tar.gz
RUN tar xf nagios-plugins-2.0.tar.gz
WORKDIR /usr/src/nagios-plugins-2.0
RUN ./configure --prefix=/usr/local/icinga --with-cgiurl=/icinga/cgi-bin --with-nagios-user=icinga --with-nagios-group=icinga
RUN make
RUN make install
# Solution for 'ping: icmp open socket: Operation not permitted'
RUN chmod u+s /usr/bin/ping

EXPOSE 80

ADD root/run.sh /root/run.sh
CMD /bin/bash /root/run.sh