#!/bin/bash

# The only argument is the new tunnel URL.
ARGO_URL="$1"

source 'substitution.sh'
source 'env_vars.sh'

# 方便查找CF地址
echo $ARGO_URL > '/usr/share/nginx/html/cf.txt'
echo "!!! URL is: $ARGO_URL !!!" 1>&2

# 输出vmess客户端配置文件到$UUID.json
perform_variable_substitution ${VAR_NAMES[@]} 'ARGO_URL' < template_client_config.json > "/usr/share/nginx/html/$UUID.json"

# 生成qr码以及网页
vmlink=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess\",\"add\":\"$ARGO_URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$ARGO_URL\",\"path\":\"$VMESS_WSPATH?ed=2560\",\"tls\":\"tls\"}" | base64 -w 0)
vllink=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=ws&host="$ARGO_URL"&path="$VLESS_WSPATH"#${DISPLAY_NAME}vless"
vllinks=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=httpupgrade&host="$ARGO_URL"&path="$TROJAN_WSPATH"#${DISPLAY_NAME}vless"
vmlink_socks=$(echo -e '\x76\x6d\x65\x73\x73')://$(echo -n "{\"v\":\"2\",\"ps\":\"${DISPLAY_NAME}vmess\",\"add\":\"$ARGO_URL\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$ARGO_URL\",\"path\":\"$VMESS_WSPATH_SOCKS?ed=2560\",\"tls\":\"tls\"}" | base64 -w 0)
vllink_socks=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=ws&host="$ARGO_URL"&path="$VLESS_WSPATH_SOCKS"#${DISPLAY_NAME}vless"
vllinks_socks=$(echo -e '\x76\x6c\x65\x73\x73')"://"$UUID"@"$ARGO_URL":443?encryption=none&security=tls&type=httpupgrade&host="$ARGO_URL"&path="$TROJAN_WSPATH_SOCKS"#${DISPLAY_NAME}vless"

# 产生订阅
echo -e "$vmlink\n$vllink\n$vllinks\n$vmlink_socks\n$vllink_socks\n$vllinks_socks" | base64 -w 0 > /usr/share/nginx/html/$UUID.txt

perform_variable_substitution ${VAR_NAMES[@]} 'ARGO_URL' 'vmlink' 'vllink' 'vllinks' 'vmlink_socks' 'vllink_socks' 'vllinks_socks' < template_webpage.html > "/usr/share/nginx/html/$UUID.html"
