FROM opensuse/leap:15.3
MAINTAINER Faldon <t.pulzer@thesecretgamer.de>

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG USER_HOME="/home/${user}"

RUN groupadd -g ${gid} ${group}
RUN useradd -d "${USER_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV HOME ${USER_HOME}
ENV SSHD_PORT 10022

RUN zypper -n install systemd; zypper clean; \
(cd /usr/lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /usr/lib/systemd/system/multi-user.target.wants/*; \
rm -f /etc/systemd/system/*.wants/*; \
rm -f /usr/lib/systemd/system/local-fs.target.wants/*; \
rm -f /usr/lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /usr/lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /usr/lib/systemd/system/basic.target.wants/*; \
rm -f /usr/lib/systemd/system/anaconda.target.wants/*;

# Install packages requirements
RUN zypper -n install git sudo curl openssl openssh unzip && zypper clean

# Install PHP
RUN zypper -n install php7 php7-APCu php7-bcmath php7-bz2 php7-calendar php7-ctype php7-curl php7-dba php7-devel php7-dom php7-embed php7-enchant php7-exif php7-fastcgi php7-fileinfo php7-firebird php7-fpm php7-ftp php7-gd php7-gettext php7-gmp php7-ice php7-iconv php7-imagick php7-intl php7-json php7-ldap php7-libphutil php7-lzf php7-maxminddb php7-mbstring php7-memcached php7-mysql php7-odbc php7-opcache php7-openssl php7-pcntl php7-pdo php7-pear php7-pecl php7-pgsql php7-phar php7-phpunit8 php7-posix php7-readline php7-redis php7-shmop php7-smbclient php7-snmp php7-soap php7-sockets php7-sodium php7-sqlite php7-sysvmsg php7-sysvsem php7-sysvshm php7-test php7-tidy php7-tokenizer php7-uuid php7-xdebug php7-xmlreader php7-xmlrpc php7-xmlwriter php7-xsl php7-zip php7-zlib uwsgi-php7 apache2-mod_php7 php-composer && zypper clean

RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd && \
    mkdir -p "${HOME}/.local/etc/ssh" && \
    cp --no-preserve=ownership /etc/ssh/sshd_config "${HOME}/.local/etc/ssh/" && \
    chown -R "${user}:${group}" "${HOME}/.local/etc/ssh"

RUN touch /run/sshd.pid && chmod 777 /run/sshd.pid

# Systemd volume
VOLUME ["/sys/fs/cgroup"]

VOLUME "${USER_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${USER_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd
ENTRYPOINT ["setup-sshd"]
