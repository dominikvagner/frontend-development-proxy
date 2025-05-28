#!/bin/bash

output=$(
  cat "$ROUTES_JSON_PATH" | jq -r 'to_entries[] | [.key, .value.url, (
    if .key | startswith("/api/") then
        if .value."rh-identity-headers" == false then
            false
        else
            true
        end
    else
        .value."rh-identity-headers" // false
    end
)] | @tsv' |
    while IFS=$'\t' read -r path url rh_identity; do
      printf "\thandle %s {\n" "$path"
      printf "\t\treverse_proxy %s {\n" "$url"
      printf "\t\t\theader_up Host {http.reverse_proxy.upstream.hostport}\n"
      printf "\t\t}\n"
      if [ "$rh_identity" = "true" ]; then
        printf "\n\t\trh_identity_transform\n"
      fi
      printf "\t}\n\n"
    done
)

LOCAL_ROUTES=$output /usr/bin/caddy run --config /etc/caddy/Caddyfile
