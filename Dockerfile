FROM rhscl/s2i-core-rhel7

ENV SUMMARY="Base image with essential libraries and tools used as a base for \
builder images like perl, python, ruby, etc." \
    DESCRIPTION="The s2i-base image, being built upon s2i-core, provides any \
images layered on top of it with all the tools needed to use source-to-image \
functionality. Additionally, s2i-base also contains various libraries needed for \
it to serve as a base for other builder images, like s2i-python or s2i-ruby." \
    NODEJS_SCL=rh-nodejs10

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="s2i base" \
      com.redhat.component="s2i-base-container" \
      name="rhscl/s2i-base-rhel7" \
      version="1" \
      com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

# This is the list of basic dependencies that all language container image can
# consume.
# Copy entitlements and subscription manager configurations
# https://github.com/BCDevOps/OpenShift4-Migration/issues/15
COPY ./etc-pki-entitlement /etc/pki/entitlement
COPY ./rhsm-conf /etc/rhsm
COPY ./rhsm-ca /etc/rhsm/ca

RUN rm /etc/rhsm-host && \
    yum repolist > /dev/null && \
    yum install -y yum-utils gettext && \
    yum-config-manager --disable \* &> /dev/null && \
    yum-config-manager --enable rhel-server-rhscl-7-rpms && \
    yum-config-manager --enable rhel-7-server-rpms && \
    yum-config-manager --enable rhel-7-server-optional-rpms && \
    yum -y install epel-release && \
    yum repolist && \
    INSTALL_PKGS="autoconf \
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
      which \
      clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

COPY config/clamd.conf /etc/clamd.conf
COPY config/freshclam.conf /etc/freshclam.conf

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
