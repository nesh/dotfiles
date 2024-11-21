#!/bin/bash
trap times EXIT

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

### CONFIG ------------------------
# PHP5_VERSIONS="5.6"
# PHP7_VERSIONS="7.1 7.2 7.3 7.4"
PHP8_VERSIONS="8.1 8.2 8.3"
### CONFIG ------------------------

APT="aptitude -VZ"

function add_to_sys_file() {
    local str="$1"
    local file="$2"

    grep -iqxF "${str}" "${file}" || echo "${str}" | sudo tee -a "${file}" || exit $?
}

function xdebug_setup() {
    local file="$1"

    add_to_sys_file "xdebug.remote_enable=1" "${file}" || exit $?
    add_to_sys_file "xdebug.mode=debug,develop" "${file}" || exit $?
    add_to_sys_file "xdebug.filename_format=%p" "${file}" || exit $?
    add_to_sys_file "xdebug.cli_color=1" "${file}" || exit $?
    add_to_sys_file "xdebug.file_link_format='javascript: var r = new XMLHttpRequest; r.open("get", "http://127.0.0.1:63342/api/file/%f:%l");r.send()'" "${file}" || exit $?

    sudo phpenmod -v ALL xdebug
}

function fpm_setup() {
    local file="$1"
    local v="$2"

    sudo sed -ie "s/\[www\]/\[www-${v}\]/g" "${file}" || exit $?

    # Make sure that $USER is member of www-data group!

    add_to_sys_file "user = $USER" "${file}" || exit $?
    add_to_sys_file "group = $USER" "${file}" || exit $?

    add_to_sys_file "listen = /run/php/php${v}-fpm.sock" "${file}" || exit $?
    add_to_sys_file "listen.owner = $USER" "${file}" || exit $?
    add_to_sys_file "listen.group = $USER" "${file}" || exit $?

    add_to_sys_file "pm = ondemand" "${file}" || exit $?
    add_to_sys_file "pm.process_idle_timeout = 60" "${file}" || exit $?

    sudo systemctl enable php${v}-fpm
    sudo service php${v}-fpm stop || exit $?
    sudo rm -rf "/run/php/php${v}-fpm.sock" || exit $?
    sudo service php${v}-fpm start || exit $?
}

set -x

## Ondrej sources
if [ ! -f '/etc/apt/sources.list.d/php.list' ]; then
    sudo apt update
    sudo apt install -y apt-transport-https lsb-release ca-certificates wget
    sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
fi

sudo apt update
sudo apt install aptitude

sudo ${APT} install htop wget curl mc mysql-common apache2 libapache2-mod-fcgid libapache2-mod-security2 boxes gettext-base netcat-traditional || exit $?
sudo a2dismod mpm_prefork || exit $?
sudo a2enmod mpm_event actions alias proxy_fcgi fcgid setenvif deflate expires headers rewrite security2 ssl || exit $?
sudo systemctl enable apache2
sudo service apache2 restart

## PHP 5
for v in $PHP5_VERSIONS; do
    sudo ${APT} install php${v} php${v}-common php${v}-cli php${v}-fpm php${v}-bcmath php${v}-curl php${v}-gd php${v}-intl php${v}-mbstring php${v}-mysql php${v}-xml php${v}-soap php${v}-xsl php${v}-zip php${v}-json php${v}-opcache php${v}-fpm php${v}-opcache php${v}-redis php${v}-xdebug || exit $?
    sudo a2dismod php${v}

    xdebug_setup "/etc/php/${v}/mods-available/xdebug.ini" || exit $?
    fpm_setup "/etc/php/${v}/fpm/pool.d/www.conf" "${v}" || exit $?
done

### PHP 7
for v in $PHP7_VERSIONS; do
    sudo ${APT} install php${v} php${v}-common php${v}-cli php${v}-fpm php${v}-bcmath php${v}-curl php${v}-gd php${v}-intl php${v}-mbstring php${v}-mysql php${v}-xml php${v}-soap php${v}-xsl php${v}-zip php${v}-json php${v}-opcache php${v}-fpm php${v}-opcache php${v}-redis php${v}-xdebug || exit $?
    sudo a2dismod php${v}

    xdebug_setup "/etc/php/${v}/mods-available/xdebug.ini" || exit $?
    fpm_setup "/etc/php/${v}/fpm/pool.d/www.conf" "${v}" || exit $?
done

### PHP 8
for v in $PHP8_VERSIONS; do
    sudo ${APT} install php${v} php${v}-common php${v}-cli php${v}-fpm php${v}-bcmath php${v}-curl php${v}-gd php${v}-intl php${v}-mbstring php${v}-mysql php${v}-xml php${v}-soap php${v}-xsl php${v}-zip php${v}-json php${v}-opcache php${v}-fpm php${v}-opcache php${v}-redis php${v}-xdebug || exit $?
    sudo a2dismod php${v}

    xdebug_setup "/etc/php/${v}/mods-available/xdebug.ini" || exit $?
    fpm_setup "/etc/php/${v}/fpm/pool.d/www.conf" "${v}" || exit $?
done

sudo service apache2 restart || exit $?

sudo aptitude autoclean
