#!/bin/sh
# Runs as root: fix the Railway volume's ownership and the listen port, then drop to
# the image's own user (uid 1000) for everything else.
set -eu

PORT="${PORT:-8000}"
case "$PORT" in ''|*[!0-9]*) echo "railway: PORT must be a number, got '$PORT'" >&2; exit 1;; esac
sed -i -E "s/listen (\[::\]:)?[0-9]+;/listen \1${PORT};/g" /etc/nginx/nginx.conf

mkdir -p /2fauth
# Railway mounts volumes owned by root; upstream runs as 1000:1000.
if [ "$(stat -c %u:%g /2fauth)" != "1000:1000" ] || find /2fauth -xdev ! -user 1000 -print -quit | grep -q .; then
  chown -R 1000:1000 /2fauth
fi
chmod 700 /2fauth

exec setpriv --reuid=1000 --regid=1000 --clear-groups /usr/local/bin/run.sh
