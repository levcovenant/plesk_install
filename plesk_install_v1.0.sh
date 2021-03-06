#!/usr/bin/env bash

# append ~/.bashrc with history flags
# history -a --> append history from all sessions
# history HISTTIMEFORMAT='%d/%m/%y %T ' - adds date and time to history
echo "Setting bashrc config"
echo "export HISTTIMEFORMAT='%d/%m/%y %T '
export PROMPT_COMMAND='history -a'" >>~/.bashrc

# activate new bashrc config
# shellcheck disable=SC1090
source ~/.bashrc

# set vim option
# syntax on - for syntax coloring
# colo delek - nice color scheme
echo "Setting vim config"
echo 'syntax on
colo delek' >>~/.vimrc

# update os and install a few packages
# bash-completion - to use tab like a human..
# a good cli text editor
# wget - for downloading from url
# mlocate - fase way to find files
# ntp - for time zone
# convenient wy to check disk space
echo "updating OS and adding a few packages"
yum upgrade -y
yum install epel-release -y
yum install bash-completion vim wget mlocate ntp ncdu -y

# stop and disable firewall service
echo "Disabling firewalld Service"
systemctl stop firewalld.service
systemctl disable firewalld.service

# site timezone to israel and enable ntp service
echo "Setting Timezone"
timedatectl set-timezone Asia/Jerusalem
systemctl enable ntpd
systemctl start ntpd

# download and change permissions to plesk installer
echo "Getting plesk installer"
wget https://autoinstall.plesk.com/plesk-installer
chmod +x plesk-installer

# install latest plesk version with specific components for better management of server
# PLESK_18_0_33 - latest plesk 03/2021
# panel - Plesk
# bind - BIND DNS server
# fail2ban - Fail2Ban
# selinux - SELinux policy
# l10n - All language localization for Plesk
# resctrl - Resource Controller (Cgroups)
# mysqlgroup - MySQL server
# roundcube - Roundcube Webmail
# spamassassin - SpamAssassin
# postfix - Postfix
# dovecot - Dovecot
# proftpd - ProFTPD
# webalizer - Webalizer
# awstats - AWStats
# mod_fcgid - mod_fcgid
# webservers - Apache
# php7.4 - PHP 7.4
# php7.3 - PHP 7.3
# php7.2 - PHP 7.2 (outdated)
# php7.0 - PHP 7.0 (outdated)
# php7.1 - PHP 7.1 (outdated)
# php8.0 - PHP 8.0
# php5.6 - PHP 5.6 (outdated)
# phpgroup - PHP from OS vendor
# config-troubleshooter - Plesk Web Server Configuration Troubleshooter
# psa-firewall - Plesk Firewall
# heavy-metal-skin - Skins and Color Schemes
# letsencrypt - Let's Encrypt
# imunifyav - ImunifyAV
# repair-kit - Repair Kit
# monitoring - Advanced Monitoring
echo "Installing Plesk...."
./plesk-installer install PLESK_18_0_33 --components panel bind fail2ban selinux l10n resctrl mysqlgroup roundcube spamassassin postfix dovecot proftpd webalizer awstats mod_fcgid webservers php7.4 php7.3 php7.2 php7.0 php7.1 php8.0 php5.6 phpgroup config-troubleshooter psa-firewall heavy-metal-skin letsencrypt imunifyav repair-kit monitoring

echo "Updating MariaDB to latest - 10.5"
# mariadb 10.5 install
echo "Dumping all databases"
MYSQL_PWD=$(cat /etc/psa/.psa.shadow) mysqldump -u admin --verbose --all-databases --routines --triggers 2 >/tmp/all-databases.sql &>/dev/null

#avoid inconsistency with repo if one exists
if [ -f "/etc/yum.repos.d/MariaDB.repo" ]; then
  mv /etc/yum.repos.d/MariaDB.repo /etc/yum.repos.d/mariadb.repo
fi

#Stopping MariaDB
echo "stopping MariaDB service"
systemctl stop mariadb

echo "creating backup of mysql directory"
cp -v -a /var/lib/mysql/ /var/lib/mysql_backup 2 &>/dev/null

echo "removing mysql-server package in case it exists"
rpm -e --nodeps "$(rpm -q --whatprovides mysql-server)"

echo "Upgrading MariaDB"

echo "#http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" >/etc/yum.repos.d/mariadb.repo

yum install MariaDB-client MariaDB-server MariaDB-compat MariaDB-shared -y

systemctl restart mariadb

MYSQL_PWD=$(cat /etc/psa/.psa.shadow) mysql_upgrade -uadmin

systemctl restart mariadb

echo "Informing Plesk of the changes (plesk sbin packagemng -sdf)"
plesk sbin packagemng -sdf

systemctl start mariadb  # to start MariaDB if not started
systemctl enable mariadb # to make sure that MariaDB will start after the server reboot automatically
