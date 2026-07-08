# syntax=docker/dockerfile:1
###############################################################################
# Production image — Reconciliation (Shibboleth-auth clinical-reasoning app)
#
# Tech stack : JS/HTML frontend (ES modules in js/, index.html at the docroot)
#              + a Slim 3 PHP API under api/public/ (PSR-7; Monolog +
#              PhpSpreadsheet via Composer). File-based storage under data/
#              (per-student dirs keyed by eppn). No SQL database.
#   !! Slim 3 + PhpSpreadsheet is an END-OF-LIFE stack pinned to PHP 7.4 (does
#      not run clean on PHP 8). This image pins php:7.4-apache for parity; the
#      real remediation for Azure is to modernize to Slim 4 / PHP 8. Flagged.
# Web server : Apache (php:7.4-apache) so the Slim front-controller rewrite
#              (api/public/.htaccess) and the root Shibboleth .htaccess are
#              honored.
#
# Composer deps (api/vendor, not committed) are built in a first stage.
#
# Authentication: Shibboleth SSO, enforced at the ingress / reverse proxy
#   (Ansible-managed). The root .htaccess `<IfModule mod_shib>` block is inert
#   without mod_shib (this image), so the proxy is the gate; the app reads
#   $_SERVER eppn/nickname/sn. No secrets/DB are baked in (see
#   .env.production.example). The dev-only Shibboleth mock lives under .ddev/
#   and is excluded from the image.
#
# EXTERNAL INTERNAL-PROJECT DEPENDENCY: the root .htaccess redirects
#   unauthenticated users (empty REMOTE_USER) to /checker/index.php — the
#   separate internal "checker" project, NOT bundled here. In production it must
#   be served at the same origin (deploy checker there / route /checker/ via the
#   ingress) or that fallback 404s.
#
# Production serves the app under a "/reconciliation/" path prefix (the frontend
# hardcodes it; see js/Modules/APIHandler.js). A self-referential symlink
# reconciliation -> docroot makes /reconciliation/... resolve (an Apache Alias
# breaks Slim's per-directory rewrite, so a symlink is used).
#
# Runs non-root (www-data) on unprivileged port 8080.
###############################################################################

# --- Stage 1: build Composer dependencies (api/vendor) -----------------------
FROM composer:2 AS vendor
WORKDIR /app
COPY api/composer.json api/composer.lock ./
# --no-dev drops rector (a dev-only dep that pulls a yanked transitive package);
# --ignore-platform-reqs because this composer image runs PHP 8 while the locked
# versions target the 7.4 runtime (exts are provided in the runtime stage).
RUN composer install --no-dev --ignore-platform-reqs --no-scripts \
        --prefer-dist --optimize-autoloader --no-interaction --no-progress

# --- Stage 2: runtime image --------------------------------------------------
FROM php:7.4-apache

# PHP extensions PhpSpreadsheet needs (zip/gd/mbstring; the rest — dom, xml,
# simplexml, ctype, iconv, fileinfo, zlib — are built into the base image).
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libonig-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" zip gd mbstring; \
    rm -rf /var/lib/apt/lists/*

# --- Apache modules the app's .htaccess needs ---
RUN set -eux; \
    a2enmod rewrite headers

# --- Run as a non-root user on an unprivileged port (8080) ---
RUN set -eux; \
    sed -ri 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf; \
    sed -ri 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf

# --- Security hardening (suppress server tokens/signature, TRACE, ETag) ---
RUN set -eux; \
    { \
      echo 'ServerTokens Prod'; \
      echo 'ServerSignature Off'; \
      echo 'TraceEnable Off'; \
      echo 'FileETag None'; \
    } > /etc/apache2/conf-available/zzz-hardening.conf; \
    a2enconf zzz-hardening

# --- Docroot policy: parse .htaccess (AllowOverride All) for the Slim rewrite +
#     Shibboleth guards; no dir listing; log to stdout/stderr ---
RUN set -eux; \
    { \
      echo '<Directory /var/www/html>'; \
      echo '    Options -Indexes +FollowSymLinks'; \
      echo '    AllowOverride All'; \
      echo '    Require all granted'; \
      echo '</Directory>'; \
      echo 'ErrorLog /dev/stderr'; \
      echo 'CustomLog /dev/stdout combined'; \
    } > /etc/apache2/conf-available/zzz-docroot.conf; \
    a2enconf zzz-docroot

# --- Application code. .dockerignore excludes .ddev/, .git/, .env*, Dockerfile,
#     the dead api/PHPExcel/ (replaced by Composer PhpSpreadsheet), api/vendor/
#     (rebuilt), data/ (runtime volume), the dead *_js_shib alt configs, logs
#     and OS junk. ---
COPY --chown=www-data:www-data . /var/www/html/

# --- Composer vendor/ from the build stage ---
COPY --from=vendor --chown=www-data:www-data /app/vendor /var/www/html/api/vendor

# --- Serve the app under its production /reconciliation/ path prefix (symlink,
#     not an Apache Alias which breaks Slim's per-dir rewrite) ---
RUN ln -sfn . /var/www/html/reconciliation

# --- Permissions: read-only app tree owned by www-data, plus the writable
#     file-storage tree under data/ (mount a volume here in production) ---
RUN set -eux; \
    find /var/www/html -type d -exec chmod 0755 {} +; \
    find /var/www/html -type f -exec chmod 0644 {} +; \
    mkdir -p /var/www/html/data/patients \
             /var/www/html/data/students \
             /var/www/html/data/metadata \
             /var/www/html/data/logs \
             /var/www/html/data/excel_dumps/students \
             /var/www/html/data/excel_dumps/students_metadata \
             /var/www/html/data/excel_dumps/patients; \
    chown -R www-data:www-data /var/www/html/data; \
    chmod -R 0775 /var/www/html/data; \
    chown -R www-data:www-data /var/run/apache2 /var/log/apache2 /var/lock; \
    chmod -R g=u /var/run/apache2 /var/log/apache2 /var/lock

USER www-data
EXPOSE 8080
VOLUME ["/var/www/html/data"]

# php:apache base CMD = apache2-foreground
