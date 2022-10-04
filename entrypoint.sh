#!/bin/bash
set -e

create_log_dir() {
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_LOG_DIR}
}

create_cache_dir() {
  mkdir -p ${SQUID_CACHE_DIR}
  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
}

create_log_dir
create_cache_dir

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# prepare a new config on each restart
cp /etc/squid/squid.conf.default /etc/squid/squid.conf

if [[ ${DISABLE_CACHE} -eq 1 ]]; then
  echo 'cache deny all' >> /etc/squid/squid.conf
  echo 'cache_log /dev/null' >> /etc/squid/squid.conf
else
  echo 'cache_log stdio:/dev/tty' >> /etc/squid/squid.conf
  echo 'cache_store_log stdio:/dev/tty' >> /etc/squid/squid.conf
fi

if [[ ${DISABLE_ACCESS_LOG} -eq 1 ]]; then
  echo 'access_log none' >> /etc/squid/squid.conf
else
  echo 'logfile_rotate 0' >> /etc/squid/squid.conf
  echo 'access_log stdio:/dev/tty' >> /etc/squid/squid.conf
fi

if [[ ${OPEN_HTTP_ACCESS} -eq 1 ]]; then
  sed -i -e 's/^http_access deny all/#http_access deny all/' /etc/squid/squid.conf
  echo 'http_access allow all' >> /etc/squid/squid.conf
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! ${DISABLE_CACHE} -eq 1 && ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
