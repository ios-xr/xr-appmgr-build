FROM centos:8

RUN cd /etc/yum.repos.d/
#Comment all the occurences of mirrorlist inside /etc/yum.repos.d/CentOS-* file
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#Replace all the occurences of mirror basurl with vault baseurl inside /etc/yum.repos.d/CentOS-* file
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN yum install -y pinentry rpm-sign rpm-build

COPY build_rpm.sh /usr/sbin/
