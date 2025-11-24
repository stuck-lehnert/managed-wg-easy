<?php

$SERVICE_FQDN = getenv('SERVICE_FQDN');
$WG_EASY_USERNAME = getenv('WG_EASY_USERNAME');
$WG_EASY_PASSWORD = getenv('WG_EASY_PASSWORD');
$REGISTRATION_HASH = getenv('REGISTRATION_HASH');

if (!$SERVICE_FQDN || !$REGISTRATION_HASH || !$WG_EASY_USERNAME || !$WG_EASY_PASSWORD) {
	header('HTTP/1.1 500 Configuration Error');
	exit;
}


$lockFile = fopen(__DIR__ . '/../issue.lock', 'c');
if (!flock($lockFile, LOCK_EX | LOCK_NB)) {
	header('HTTP/1.1 503 Service Unavailable');
	exit;
}

if (!isset($_GET['token']) || !isset($_GET['pcname'])) {
	header('HTTP/1.1 400 Bad Request');
	exit;
}

$token = trim($_GET['token']);
$pcname = trim($_GET['pcname']);

if (strlen($token) < 1 || strlen($pcname) < 1) {
	header('HTTP/1.1 400 Bad Request');
	exit;
}

if (strlen($pcname) > 40 || !preg_match('/^[a-zA-Z0-9_\-]+$/', $pcname)) {
	header('HTTP/1.1 400 Bad Request');
	exit;
}

if (!password_verify($token, $REGISTRATION_HASH)) {
	header('HTTP/1.1 401 Unauthorized');
	exit;
}

// fetch currently registered clients
$ch = curl_init("https://$SERVICE_FQDN/api/client");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
curl_setopt($ch, CURLOPT_USERPWD, "$username:$password");
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);
$res = curl_exec($ch);
if (!$res) {
	header('HTTP/1.1 500 Internal API Error');
	exit;
}

$clients = json_decode($res);

header("Content-Type: application/json");
echo $res;

