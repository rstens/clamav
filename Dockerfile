FROM centos/s2i-core-centos8


RUN yum -y install epel-release
RUN yum -y update
RUN yum clean all
RUN yum install -y clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd

COPY config/clamd.conf /etc/clamd.conf
COPY config/freshclam.conf /etc/freshclam.conf

RUN chown -R 1001:0 /opt/app-root/src
RUN chmod -R ug+rwx /opt/app-root/src

RUN wget -t 5 -T 99999 -O /opt/app-root/src/main.cvd http://database.clamav.net/main.cvd && \
   wget -t 5 -T 99999 -O /opt/app-root/src/daily.cvd http://database.clamav.net/daily.cvd && \
   wget -t 5 -T 99999 -O /opt/app-root/src/bytecode.cvd http://database.clamav.net/bytecode.cvd && \
   chown clamupdate:clamupdate /opt/app-root/src/*.cvd

USER 1001

EXPOSE 3310

CMD clamd -c /etc/clamd.conf
