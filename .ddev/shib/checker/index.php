<?php
/**
 * DDEV-only stand-in for the internal "checker" project (not part of this
 * repo). Production's root .htaccess internally rewrites anonymous requests
 * to /checker/index.php?target=...; locally we send the user straight into
 * the real Shibboleth login and back to where they were headed.
 */
$target = isset($_GET['target']) && is_string($_GET['target']) ? $_GET['target'] : '/';
if ($target === '' || $target[0] !== '/') {
    $target = '/';
}
$return = 'https://' . $_SERVER['HTTP_HOST'] . $target;
header('Location: /Shibboleth.sso/Login?target=' . rawurlencode($return));
http_response_code(302);
