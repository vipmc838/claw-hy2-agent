#!/bin/bash
set -e

echo "✅ 正在启动 Nezha Agent，配置如下："
echo "NZ_SERVER: ${NZ_SERVER}"
echo "NZ_UUID: ${NZ_UUID}"
echo "NZ_CLIENT_SECRET: ${NZ_CLIENT_SECRET}"
echo "NZ_TLS: ${NZ_TLS}"
echo "DASHBOARD_VERSION: ${DASHBOARD_VERSION:-latest}"

# 生成 Nezha Agent 配置
cat > /app/config.yaml <<EOF
debug: true
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 4
server: ${NZ_SERVER}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: ${NZ_TLS}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: ${NZ_UUID}
client_secret: ${NZ_CLIENT_SECRET}
EOF

echo "✅ 正在启动 Hysteria2，配置如下："
echo "SERVER_DOMAIN: ${SERVER_DOMAIN}"
echo "UDP_PORT: ${UDP_PORT}"
echo "PASSWORD: ${PASSWORD}"

# 创建 Hysteria2 配置文件
cat > /etc/hysteria/config.yaml <<EOF
listen: :${UDP_PORT}

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: ${PASSWORD}

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF

# 启动 Hysteria2 到后台
/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml &

# 获取公网 IP 和国家代码
SERVER_IP=$(curl -s https://api.ipify.org)
COUNTRY_CODE=$(curl -s https://ipapi.co/${SERVER_IP}/country/ || echo "XX")

echo "✅ Hysteria2 启动成功"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接配置（请将端口替换为爪云分配的外网 UDP 端口）："
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${UDP_PORT}?sni=bing.com&insecure=1#claw.cloud-hy2-${COUNTRY_CODE}"
echo "------------------------------------------------------------------------"

# 启动 Nezha Agent，作为主进程（PID 1）
exec ./nezha-agent --config /app/config.yaml
