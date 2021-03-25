FROM registry.access.redhat.com/rhel

ENV SUMMARY="" \
    DESCRIPTION=""

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="rhel ataomic" \
      com.redhat.component="atomic" \
      name="registry.redhat.io/rhel7/rhel-atomic" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

# This is the list of basic dependencies that all language container image can
# consume.
# Copy entitlements and subscription manager configurations
# https://github.com/BCDevOps/OpenShift4-Migration/issues/15
COPY ./etc-pki-entitlement /etc/pki/entitlement
COPY ./rhsm-conf /etc/rhsm
COPY ./rhsm-ca /etc/rhsm/ca

RUN rm /etc/rhsm-host
RUN yum repolist > /dev/null
RUN yum install -y yum-utils gettext
RUN yum-config-manager --disable \* &> /dev/null
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms
RUN yum-config-manager --enable rhel-7-server-rpms
RUN yum-config-manager --enable rhel-7-server-optional-rpms
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
RUN yum repolist > /dev/null
RUN INSTALL_PKGS="autoconf \
      automake \
      bzip2 \
      gcc-c++ \
      gdb \
      git \
      lsof \
      make \
      patch \
      procps-ng \
      unzip \
      wget \
      which" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS
    
RUN yum install -y clamav
RUN yum install -y clamd
    
RUN  yum -y clean all --enablerepo='*'

COPY config/clamd.conf /etc/clamd.conf
COPY config/freshclam.conf /etc/freshclam.conf

RUN mkdir /opt/app-root
RUN mkdir /opt/app-root/src
RUN chown -R 1001:0 /opt/app-root/src
RUN chmod -R ug+rwx /opt/app-root/src

# initial update of av databases
RUN wget -t 5 -T 99999 -O /opt/app-root/src/main.cvd https://clamav-biohub.s3.ca-central-1.amazonaws.com/main.cvd && \
    wget -t 5 -T 99999 -O /opt/app-root/src/daily.cvd https://clamav-biohub.s3.ca-central-1.amazonaws.com/daily.cvd && \
    wget -t 5 -T 99999 -O /opt/app-root/src/bytecode.cvd https://clamav-biohub.s3.ca-central-1.amazonaws.com/bytecode.cvd && \
    chown clamupdate:clamupdate /opt/app-root/src/*.cvd

USER 1001

EXPOSE 3310

CMD clamd -c /etc/clamd.conf
