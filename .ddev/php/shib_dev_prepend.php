<?php
/**
 * Hardened local-dev Shibboleth authentication simulation for Reconciliation.
 *
 * WHY: production runs Apache + mod_shib, which populates $_SERVER['eppn'|'nickname'|'sn']
 * and REMOTE_USER. DDEV has no mod_shib, so the Slim API (api/public/index.php reads
 * $_SERVER['eppn'] etc.) would see no identity. This seeds dummy attributes so the app
 * behaves as if a user is authenticated.
 *
 * SECURITY (see memory: shibboleth-dev-bypass-hardened-pattern):
 *   1. FENCED OFF — lives under .ddev/, wired via .ddev/php/dev.ini auto_prepend_file.
 *      Neither path is in the deployable tree, so it cannot run on the Azure servers.
 *   2. FAIL CLOSED — gated on an explicit, server-set APP_ENV that defaults to
 *      "production". Unless APP_ENV is local/development this is an immediate no-op.
 *   3. NON-DESTRUCTIVE — only fills attributes that are ABSENT, so a real Shibboleth
 *      session is never overwritten.
 *   4. NO REAL CREDENTIALS — dummy values only, overridable via MOCK_* env vars.
 */

// --- Gate: explicit environment flag, default to production -----------------
$appEnv = getenv('APP_ENV');
if ($appEnv === false || $appEnv === '') {
    $appEnv = $_SERVER['APP_ENV'] ?? 'production';
}
if (!in_array(strtolower($appEnv), ['local', 'development', 'dev'], true)) {
    return; // production / unknown -> do nothing, real Shibboleth is in charge
}

// --- Resolve mock identity (env overrides -> safe defaults) -----------------
$mock = [
    'eppn'        => getenv('MOCK_EPPN')     ?: 'test.student@stonybrook.edu',
    'nickname'    => getenv('MOCK_NICKNAME') ?: 'Test',
    'sn'          => getenv('MOCK_SN')       ?: 'Student',
];
// REMOTE_USER mirrors eppn (what mod_shib sets for the authenticated principal).
$mock['REMOTE_USER'] = $mock['eppn'];

// --- Seed only when absent (never clobber a real session) -------------------
foreach ($mock as $key => $value) {
    if (empty($_SERVER[$key])) {
        $_SERVER[$key] = $value;
    }
}
