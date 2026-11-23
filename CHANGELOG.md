# Changelog

## 9.0.2 (2026-11-23)

First release of the template.

- 2FAuth `9.0.2`, official image `2fauth/2fauth:9.0.2@sha256:6774efa7c612e424eb17a54e2373524d9a04af6cad7e38d85d76fed87f6a48bd`.
- SQLite database, OAuth keys and icons on the `/2fauth` volume.
- First boot creates the administrator from `ADMIN_EMAIL`/`ADMIN_PASSWORD` and turns public registration off.
- nginx and PHP-FPM are supervised by the start script: if either stops, the service exits non-zero so Railway restarts it.
- Health check: `/up`.
