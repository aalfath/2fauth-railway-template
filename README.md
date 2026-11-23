[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/2fauth-1?utm_medium=integration&utm_source=button&utm_campaign=2fauth)

# Deploy and Host 2FAuth on Railway

2FAuth is an open-source web app that manages your two-factor authentication (2FA) accounts and generates their TOTP, HOTP and Steam Guard codes in the browser. You add accounts by scanning or uploading a QR code, sort them into groups, and import from Google Authenticator, Aegis or 2FAS. Secrets stay on your own server.

## About Hosting 2FAuth

This template runs one service, **2FAuth**, built from the [aalfath/2fauth-railway-template](https://github.com/aalfath/2fauth-railway-template) repo. The repo's Dockerfile pins the official `2fauth/2fauth:9.0.2` image by tag and digest. The SQLite database, OAuth keys and uploaded icons live on a Railway volume at `/2fauth`, so they survive restarts and redeploys. On the first boot the start script runs the migrations, creates the administrator from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD`, and turns public registration off, so a stranger can't claim your instance. `APP_KEY` is generated at deploy and encrypts sessions and stored data. Railway checks `/up` for health and restarts the service if nginx or PHP-FPM stops.

## Common Use Cases

* Reach your 2FA codes from any browser when your phone is not at hand
* Keep a self-hosted, backed-up copy of all your TOTP/HOTP secrets instead of a phone-only app
* Share a set of 2FA accounts with other users of the same instance

## Dependencies for 2FAuth Hosting

* The official `2fauth/2fauth` image (PHP 8.4, nginx, SQLite), version 9.0.2
* A Railway volume mounted at `/2fauth`

### Deployment Dependencies

* 2FAuth source and releases: https://github.com/Bubka/2FAuth/releases
* 2FAuth documentation: https://docs.2fauth.app/
* Docker image: https://hub.docker.com/r/2fauth/2fauth
* Template repo: https://github.com/aalfath/2fauth-railway-template

### Implementation Details

**After deploy:** open the service's public URL and sign in with `ADMIN_EMAIL` and the `ADMIN_PASSWORD` shown in the service's Variables tab. Change the password under Settings, and consider adding a passkey (WebAuthn). The admin can add users under Admin > Users, or turn registration back on under Admin > Auth.

**Variables:** `ADMIN_EMAIL` is the only prompt. `ADMIN_PASSWORD` and `APP_KEY` are generated. `ADMIN_EMAIL` and `ADMIN_PASSWORD` are read on the first boot only; after that, manage users and passwords in the app. Don't change `APP_KEY` after the first deploy: it encrypts your sessions and, if you turn on encryption, your stored secrets. Optional settings such as email (`MAIL_MAILER`, `MAIL_HOST`, …), `APP_TIMEZONE` or SSO can be added as variables; see the [2FAuth configuration docs](https://docs.2fauth.app/getting-started/config/env-vars/).

**Resources:** idles at about 30 MB of RAM and peaked near 100 MB in our tests, so it fits Railway's smallest plan (0.5 GB).

**Updates:** when a new 2FAuth release is tested, we bump the pinned image in the template repo and note it in `CHANGELOG.md`. Railway then shows "update available" on your service, and you choose when to apply it. Migrations run on start, and your data stays on the volume.

## Why Deploy 2FAuth on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying 2FAuth on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *(prompt)* | Email of the first administrator, created on the first boot only |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | Password of the first administrator (first boot only) |
| `APP_KEY` | `${{secret(32)}}` | Laravel encryption key. Never change it after the first deploy |
| `APP_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public URL, used for links and WebAuthn |
| `PORT` | `8000` | Port nginx listens on |

Fixed in the start script, each overridable with a variable: `APP_ENV=local` (upstream's recommendation), `LOG_CHANNEL=stderr`, `TRUSTED_PROXIES=*`, `DB_CONNECTION=sqlite`, `SITE_OWNER=$ADMIN_EMAIL`.

## How updates reach you

Railway sends an "update available" notice to services built from this repo whenever `main` changes. Read `CHANGELOG.md` before applying one: breaking changes are listed first.

## Repo layout

- `Dockerfile`: the pinned official image plus the wrapper below
- `start.sh`: runs as root, fixes the volume's ownership and the port, then drops to uid 1000
- `run.sh`: upstream's setup steps (minus supervisord), the first-boot admin, then nginx + PHP-FPM; exits non-zero if either stops
- `create-admin.php`: creates the first admin and turns public registration off, only when no user exists yet
