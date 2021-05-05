
```
export DEPLOY_CDN_Ali_Key="AK"
export DEPLOY_CDN_Ali_Secret="SK"
export DEPLOY_CDN_Ali_Prefix="www.example.com, blog.example.com"

acme.sh --deploy -d example.com --deploy-hook cdn_ali
```

## 参考

- https://github.com/acmesh-official/acme.sh/issues/1461
- https://github.com/acmesh-official/acme.sh/pull/1466
- https://github.com/acmesh-official/acme.sh/pull/1099