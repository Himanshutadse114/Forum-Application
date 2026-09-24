<?php
// config/jwt.php

function base64UrlEncode($data) {
    return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
}

function base64UrlDecode($data) {
    $remainder = strlen($data) % 4;
    if ($remainder) {
        $padlen = 4 - $remainder;
        $data .= str_repeat('=', $padlen);
    }
    return base64_decode(str_replace(['-', '_'], ['+', '/'], $data));
}

function generateJWT($headers, $payload, $secret) {
    $headers_encoded = base64UrlEncode(json_encode($headers));
    $payload_encoded = base64UrlEncode(json_encode($payload));
    
    $signature = hash_hmac('SHA256', "$headers_encoded.$payload_encoded", $secret, true);
    $signature_encoded = base64UrlEncode($signature);
    
    return "$headers_encoded.$payload_encoded.$signature_encoded";
}

function isJWTValid($jwt, $secret) {
    $tokenParts = explode('.', $jwt);
    if (count($tokenParts) !== 3) return false;
    
    $header = base64UrlDecode($tokenParts[0]);
    $payload = base64UrlDecode($tokenParts[1]);
    $signature_provided = $tokenParts[2];
    
    // Check expiration
    $payload_arr = json_decode($payload, true);
    if (isset($payload_arr['exp']) && $payload_arr['exp'] < time()) {
        return false; // Token expired
    }
    
    // Verify signature
    $base64_url_header = $tokenParts[0];
    $base64_url_payload = $tokenParts[1];
    $signature = hash_hmac('SHA256', "$base64_url_header.$base64_url_payload", $secret, true);
    $base64_url_signature = base64UrlEncode($signature);
    
    return ($base64_url_signature === $signature_provided);
}

function getJWTPayload($jwt) {
    $tokenParts = explode('.', $jwt);
    return json_decode(base64UrlDecode($tokenParts[1]), true);
}
?>
