#!/bin/sh
# Runs as uid 1000: upstream setup, first-boot admin, then php-fpm + nginx.
set -eu

# Sensible fixed settings for Railway (each can still be overridden by a variable).
# Upstream recommends "local": "production" makes its console setup commands ask for confirmation.
export APP_ENV="${APP_ENV:-local}"
export APP_DEBUG="${APP_DEBUG:-false}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"
export LOG_LEVEL="${LOG_LEVEL:-notice}"
export TRUSTED_PROXIES="${TRUSTED_PROXIES:-*}"
export DB_CONNECTION="${DB_CONNECTION:-sqlite}"
export SITE_OWNER="${SITE_OWNER:-${ADMIN_EMAIL:-}}"
export WEBAUTHN_NAME="${WEBAUTHN_NAME:-2FAuth}"

if [ -z "${APP_KEY:-}" ]; then
  echo "railway: APP_KEY is empty; refusing to start (it encrypts sessions and secrets)" >&2
  exit 1
fi

# One setup at a time, even if two deploys overlap on the same volume.
exec 9>/2fauth/.railway-setup.lock
flock 9
/usr/local/bin/2fauth-setup.sh
php /usr/local/share/railway/create-admin.php
flock -u 9
exec 9>&-

FPM_PID=""; NGINX_PID=""
stop() {
  echo "railway: stopping"
  [ -n "$NGINX_PID" ] && kill -QUIT "$NGINX_PID" 2>/dev/null || true
  [ -n "$FPM_PID" ] && kill -QUIT "$FPM_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}
trap stop TERM INT

/usr/sbin/php-fpm84 -F &
FPM_PID=$!
/usr/sbin/nginx -g 'daemon off;' &
NGINX_PID=$!

# Exit non-zero as soon as either process is gone (busybox `wait -n` misses a child
# that died before it was called, so poll instead).
while kill -0 "$FPM_PID" 2>/dev/null && kill -0 "$NGINX_PID" 2>/dev/null; do
  sleep 2 &
  wait $! 2>/dev/null || true
done
set +e
code=0
if ! kill -0 "$FPM_PID" 2>/dev/null; then wait "$FPM_PID" 2>/dev/null; code=$?; who=php-fpm; else wait "$NGINX_PID" 2>/dev/null; code=$?; who=nginx; fi
echo "railway: $who exited unexpectedly (code $code); stopping so Railway restarts the service" >&2
kill -TERM "$FPM_PID" "$NGINX_PID" 2>/dev/null || true
[ "$code" -eq 0 ] && code=1
exit "$code"
