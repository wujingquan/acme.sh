#!/usr/bin/env sh

TencentCDN_API="https://cdn.tencentcloudapi.com/"
# TencentCDN_API="http://acmesh.frp.wujingquan.com/"

tencent_cdn_deploy() {
  # str1=$(echo -n foobar | sha256sum)
  # # echo -n $str1
  # echo ${str1: 2}
  # var=$(echo -n "foobar" | sha256sum | awk '{print $1}')
  # echo $var
  # return 1
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  # 读取环境变量 或 配置文件里的变量
  # 如果读取不到环境的变量就会读取配置文件的变量
  DEPLOY_Tencent_CDN_Key="${DEPLOY_Tencent_CDN_Key:-$(_readdomainconf DEPLOY_Tencent_CDN_Key)}"
  DEPLOY_Tencent_CDN_Secret="${DEPLOY_Tencent_CDN_Secret:-$(_readdomainconf DEPLOY_Tencent_CDN_Secret)}"
  DEPLOY_Tencent_CDN_Prefix="${DEPLOY_Tencent_CDN_Prefix:-$(_readdomainconf DEPLOY_Tencent_CDN_Prefix)}"

  # 判断是否设置了 accessToken 、accessKey
  if [ -z "$DEPLOY_Tencent_CDN_Key" ] || [ -z "$DEPLOY_Tencent_CDN_Secret" ]; then
    DEPLOY_Tencent_CDN_Key=""
    DEPLOY_Tencent_CDN_Secret=""
    _err "You don't specify tentcent cdn api key and secret yet."
    return 1
  fi

  #save the api key and secret to the account conf file.
  # 保存
  _savedomainconf DEPLOY_Tencent_CDN_Key "$DEPLOY_Tencent_CDN_Key"
  _savedomainconf DEPLOY_Tencent_CDN_Secret "$DEPLOY_Tencent_CDN_Secret"
  _savedomainconf DEPLOY_Tencent_CDN_Prefix "$DEPLOY_Tencent_CDN_Prefix"

  # read cert and key files and urlencode both
  _certnamestr=$DEPLOY_Tencent_CDN_Prefix'-'$(sha1sum "$_ccert" | cut -c1-20)
  _certtext=$(sed '/^$/d' <"$_cfullchain")
  _keytext=$(sed '/^$/d' <"$_ckey")
  _certstr=$(_ali_urlencode "$_certtext")
  _keystr=$(_ali_urlencode "$_keytext")

  _debug _certname "$_certnamestr"
  _debug2 _cert "$_certstr"
  _debug2 _key "$_keystr"

  _debug "Set Cert"
  # _set_cert_query "$(_ali_urlencode "$DEPLOY_Tencent_CDN_Prefix")" "$(_ali_urlencode "$_certnamestr")" "$_certstr" "$_keystr" && _ali_rest "Set Cert"
  # _ali_rest "Set Cert"
  # echo "------------------_cfullchain-------------"
  # echo "$_cfullchain"
  # echo "------------------_cfullchain-------------"
  string_fullchain=$(sed '/^$/d' "$_cfullchain")
  # echo "$string_fullchain"
  string_key=$(sed '/^$/d' "$_ckey")
  _ali_rest "$string_fullchain" "$string_key"
  return 0
}

########  Private functions #####################
########      私有方法       #####################

_set_cert_query() {
  query=''
  query=$query'AccessKeyId='$DEPLOY_CDN_Ali_Key
  query=$query'&Action=BatchSetCdnDomainServerCertificate'
  query=$query'&CertName='$2
  query=$query'&DomainName='$1
  query=$query'&Format=json'
  query=$query'&SSLPri='$4
  query=$query'&SSLProtocol=on'
  query=$query'&SSLPub='$3
  query=$query'&SignatureMethod=HMAC-SHA1'
  query=$query"&SignatureNonce=$(_ali_nonce)"
  query=$query'&SignatureVersion=1.0'
  query=$query'&Timestamp='$(_timestamp)
  query=$query'&Version=2018-05-10'

  query=$query'&Action=UpdateDomainConfig'
  query=$query'&Version=2018-06-06'
  query=$query'&Domain='$


  # echo $query
  echo $3
  echo $4

  # _debug2 query "$query"
}

# 
_ali_rest() {
  
  echo -n $1
  echo -n $2

  signature=$(printf "%s" "GET&%2F&$(_ali_urlencode "$query")" | _hmac "sha1" "$(printf "%s" "$DEPLOY_CDN_Ali_Secret&" | _hex_dump | tr -d " ")" | _base64)
  signature=$(_ali_urlencode "$signature")
  url="$TencentCDN_API?$query&Signature=$signature"

  # export _H1="X-TC-Action: UpdateDomainConfig"
  # export _H1="X-TC-Action: $(echo -n 'foobar' | sha256sum | awk '{print $1}')"
  HTTPRequestMethod="POST"
  CanonicalURI="/"
  CanonicalQueryString=""
  CanonicalHeaders1="content-type:application/json; charset=utf-8\n"
  CanonicalHeaders2="host:cdn.tencentcloudapi.com\n"
  CanonicalHeaders="${CanonicalHeaders1}${CanonicalHeaders2}"
  SignedHeaders="content-type;host"
  __Domain="projects.wujingquan.com"
  # RequestPayload="{\"Domain\":\"${__Domain}\",\"Https\":{\"Switch\":\"on\",\"CertInfo\":{\"Certificate\":\""$1"\",\"PrivateKey\":\""$2"\"}}}"
  RequestPayload="{\"Domain\":\"${__Domain}\",\"Https\":{\"Switch\":\"on\",\"CertInfo\":{\"Certificate\":\"$1\",\"PrivateKey\":\"$2\"}}}"
  # RequestPayload="{\"name\":\"$2\"}"
  echo $RequestPayload
  HashedRequestPayload="$(echo -n $RequestPayload | sha256sum | awk '{print $1}' | awk '{print tolower($0)}')"
  CanonicalRequest="${HTTPRequestMethod}\n${CanonicalURI}\n${CanonicalQueryString}\n${CanonicalHeaders}\n${SignedHeaders}\n${HashedRequestPayload}"
  echo $CanonicalRequest

  Algorithm="TC3-HMAC-SHA256"
  RequestTimestamp=$(_timestamp)
  # RequestTimestamp=1639103913
  # echo $RequestTimestamp
  CredentialScope="$(_date)/cdn/tc3_request"
  HashedCanonicalRequest="$(echo -n $CanonicalRequest | sha256sum | awk '{print $1}' | awk '{print tolower($0)}')"
  StringToSign="${Algorithm}\n${RequestTimestamp}\n${CredentialScope}\n${HashedCanonicalRequest}"
  echo $StringToSign

  SecretKey=""
  SecretDate="$(echo -n $(_date) | openssl dgst -sha256 -binary -hmac TC3$SecretKey)"
  echo -n $SecretDate | base64
  SecretService="$(echo -n cdn | openssl dgst -sha256 -binary -hmac "$SecretDate")"
  echo -n $SecretService | base64
  SecretSigning="$(echo -n tc3_request | openssl dgst -sha256 -binary -hmac "$SecretService")"
  echo -n $SecretSigning | base64
  Signature="$(echo -n $StringToSign | openssl dgst -sha256 -hex -hmac "$SecretSigning" | awk '{print $2}' | awk '{print tolower($0)}')"
  echo $Signature


  export _H1="X-TC-Action: UpdateDomainConfig"
  export _H2="X-TC-Timestamp: ${RequestTimestamp}"
  export _H3="X-TC-Version: 2018-06-06"
  export _H4="Authorization: TC3-HMAC-SHA256 Credential=/$(_date)/cdn/tc3_request, SignedHeaders=content-type;host, Signature=${Signature}"
  export _H5="content-type:application/json; charset=utf-8"
  _post "$RequestPayload" "$TencentCDN_API"
  # sslcert_response=$(_post "$RequestPayload" "$TencentCDN_API" 1 "POST" "application/json; charset=utf-8" | _dbase64 "multiline")
  # echo $sslcert_response
  # if ! response="$(_get "$url")"; then
  #   _err "Error <$1>"
  #   return 1
  # fi

  # _debug2 response "$response"
  # if [ -z "$2" ]; then
  #   message="$(echo "$response" | _egrep_o "\"Message\":\"[^\"]*\"" | cut -d : -f 2 | tr -d \")"
  #   if [ "$message" ]; then
  #     _err "$message"
  #     return 1
  #   fi
  # fi
}

_ali_urlencode() {
  # urlencode <string>
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C

  _str="$1"
  _str_length="${#1}"
  i=1
  while [ "$i" -le "$_str_length" ]; do
    _str_c="$(printf "%s" "$_str" | head -c "$i" | tail -c 1)"
    case $_str_c in
      [a-zA-Z0-9.~_-]) printf "%s" "$_str_c" ;;
      "") printf "%s" "%0A" ;;
      *) printf '%%%02X' "'$_str_c" ;;
    esac
    i=$((i + 1))
  done

  LC_COLLATE=$old_lc_collate
}

_ali_nonce() {
  #_head_n 1 </dev/urandom | _digest "sha256" hex | cut -c 1-31
  #Not so good...
  date +"%s%N"
}

_timestamp() {
  # date -u +"%Y-%m-%dT%H%%3A%M%%3A%SZ"
  date '+%s'
}
_date() {
  date "+%Y-%m-%d"
}