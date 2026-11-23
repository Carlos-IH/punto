#!/bin/sh

set -eu

# Apache cannot load more than one MPM. Clean the enabled links again at
# runtime because the container may be rebuilt from a cached/base layer.
rm -f /etc/apache2/mods-enabled/mpm_*.load \
      /etc/apache2/mods-enabled/mpm_*.conf
a2enmod mpm_prefork rewrite >/dev/null

mpm_count="$(apache2ctl -M 2>&1 | awk '/mpm_[^ ]+_module/ { count++ } END { print count + 0 }')"
if [ "$mpm_count" -ne 1 ]; then
    echo "Apache must have exactly one MPM enabled; found $mpm_count." >&2
    apache2ctl -M >&2 || true
    exit 1
fi

if [ -z "${ALLOWED_HOSTNAMES:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    export ALLOWED_HOSTNAMES="$RAILWAY_PUBLIC_DOMAIN"
fi

php spark env:provision
exec apache2-foreground
