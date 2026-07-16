<?php
/**
 * Reconciliation-specific test identities. Roles are app-side: the API's
 * hardcoded admin allowlist (api/public/index.php) matches on eppn, so the
 * "admin" login maps to an allowlisted identity. Local-dev only.
 */
return [
    'admin:adminpass' => [
        'cn' => ['pstdenis'],
        'eppn' => ['pstdenis@stonybrook.edu'],
        'mail' => ['pstdenis@stonybrook.edu'],
        'givenName' => ['Paul'],
        'nickname' => ['Paul'],
        'sn' => ['St. Denis'],
        'displayName' => ['Paul St. Denis'],
        'affiliation' => ['faculty@stonybrook.edu'],
    ],
];
