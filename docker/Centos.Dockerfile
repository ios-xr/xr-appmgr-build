FROM centos:8

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN yum install -y pinentry rpm-sign rpm-build

COPY build_rpm.sh /usr/sbin/
# FROM akshshar/xr-wrl7

# COPY build_rpm.sh /usr/sbin/
