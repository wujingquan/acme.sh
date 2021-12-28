_timestamp() {
  # date -u +"%Y-%m-%dT%H%%3A%M%%3A%SZ"
  date '+%s'
}
_date() {
  date "+%Y-%m-%d"
}

HTTPRequestMethod="POST"
CanonicalURI="/"
CanonicalQueryString=""
CanonicalHeaders1="content-type:application/json; charset=utf-8\n"
CanonicalHeaders2="host:cdn.tencentcloudapi.com\n"
CanonicalHeaders="${CanonicalHeaders1}${CanonicalHeaders2}"
SignedHeaders="content-type;host"
RequestPayload='{}'
HashedRequestPayload="$(echo -n $RequestPayload | sha256sum | awk '{print $1}' | awk '{print tolower($0)}')"
CanonicalRequest="${HTTPRequestMethod}\n${CanonicalURI}\n${CanonicalQueryString}\n${CanonicalHeaders}\n${SignedHeaders}\n${HashedRequestPayload}"

echo $CanonicalRequest

Algorithm="TC3-HMAC-SHA256"
# RequestTimestamp=$(_timestamp)
RequestTimestamp=1639103913
CredentialScope="$(_date)/cdn/tc3_request"
HashedCanonicalRequest="$(echo -n $CanonicalRequest | sha256sum | awk '{print $1}' | awk '{print tolower($0)}')"
StringToSign="${Algorithm}\n${RequestTimestamp}\n${CredentialScope}\n${HashedCanonicalRequest}"

echo $StringToSign

SecretKey="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
SecretDate="$(echo -n $(_date) | openssl dgst -sha256 -binary -hmac TC3$SecretKey)"
echo -n $SecretDate | base64
SecretService="$(echo -n cdn | openssl dgst -sha256 -binary -hmac "$SecretDate")"
echo -n $SecretService | base64
SecretSigning="$(echo -n tc3_request | openssl dgst -sha256 -binary -hmac "$SecretService")"
Signature="$(echo -n $StringToSign | openssl dgst -sha256 -hex -hmac $SecretSigning | awk '{print $2}' | awk '{print tolower($0)}')"
echo $Signature


