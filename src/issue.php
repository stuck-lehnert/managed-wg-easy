<?php

$WG_EASY_IPV4 = getenv('WG_EASY_IPV4');
$WG_EASY_USERNAME = getenv('WG_EASY_USERNAME');
$WG_EASY_PASSWORD = getenv('WG_EASY_PASSWORD');
$REGISTRATION_HASH = getenv('REGISTRATION_HASH');

if (!$WG_EASY_IPV4 || !$REGISTRATION_HASH || !$WG_EASY_USERNAME || !$WG_EASY_PASSWORD) {
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

$BASIC_AUTH = "$WG_EASY_USERNAME:$WG_EASY_PASSWORD";

function build_request(string $url) {
	global $BASIC_AUTH;

	$ch = curl_init($url);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
	curl_setopt($ch, CURLOPT_USERPWD, $BASIC_AUTH);
	curl_setopt($ch, CURLOPT_HTTPHEADER, ['Accept: application/json']);
	return $ch;
}

function fetch_request($ch): string {
	$res = curl_exec($ch);
	if (!$res) {
		header('HTTP/1.1 500 Internal API Error');
		echo curl_error($ch);
		exit;
	}

	return $res;
}

function fetch_json($ch): array {
	$res = fetch_request($ch);
	$json = json_decode($res, true);
	if (isset($json['error'])) {
		header('HTTP/1.1 500 Internal API Error');
		header('Content-Type: application/json');
		echo $res;
		exit;
	}

	return $json;
}



$ch = build_request("http://$WG_EASY_IPV4/api/client");
$clients = fetch_json($ch);

$client_exists = false;
foreach($clients as $client) {
	if (strtolower($client['name']) == strtolower($pcname)) {
		$client_exists = true;
		break;
	}
}

if (!$client_exists) {
	$ch = build_request("http://$WG_EASY_IPV4/api/client");
	curl_setopt($ch, CURLOPT_POST, true);
	curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
		'name' => strtolower($pcname),
		'expiresAt' => null,
	]));
	curl_setopt($ch, CURLOPT_HTTPHEADER, [
		'Content-Type: application/json',
		'Accept: application/json',
	]);
	fetch_json($ch);

	$ch = build_request("http://$WG_EASY_IPV4/api/client");
	$clients = fetch_json($ch);
}


foreach ($clients as $client) {
	if (strtolower($client['name']) == strtolower($pcname)) {
		$client_id = $client['id'];
		$ch = build_request("http://$WG_EASY_IPV4/api/client/$client_id/configuration");
		$config = fetch_request($ch);

		header('Content-Type: text/plain');
		echo $config;
		exit;
	}
}


// should not be reached
header('HTTP/1.1 500 Internal Server Error');
exit;
