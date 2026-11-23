# 2FAuth on Railway: the official image, pinned by version and digest, plus a small wrapper.
# Bump the pin (tag AND digest) here and add a CHANGELOG.md entry; a merge to main notifies deployers.
FROM 2fauth/2fauth:9.0.2@sha256:6774efa7c612e424eb17a54e2373524d9a04af6cad7e38d85d76fed87f6a48bd

USER root

# Upstream's entrypoint does the setup (SQLite on /2fauth, storage symlink, migrations,
# Passport keys, caches) and then runs supervisord, which keeps running when nginx or
# php-fpm dies (autorestart=false). We reuse the setup part only and supervise the two
# processes ourselves, so an unexpected stop exits non-zero and Railway restarts it.
# uid/gid 1000 owns /srv and /2fauth in the upstream image but has no passwd entry.
RUN (getent group 1000 >/dev/null || addgroup -g 1000 tfa) \
 && (getent passwd 1000 >/dev/null || adduser -D -H -h /srv -u 1000 -G tfa -s /bin/sh tfa)

RUN grep -qx 'supervisord' /usr/local/bin/entrypoint.sh \
 && sed '/^supervisord$/d' /usr/local/bin/entrypoint.sh > /usr/local/bin/2fauth-setup.sh \
 && chmod 555 /usr/local/bin/2fauth-setup.sh \
 && chmod 644 /etc/nginx/nginx.conf

COPY --chmod=555 start.sh run.sh /usr/local/bin/
COPY --chmod=444 create-admin.php /usr/local/share/railway/create-admin.php

EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/start.sh"]
