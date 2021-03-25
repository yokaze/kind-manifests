cat <<EOF > /var/log/sample.log
$(date +%Y-%m-%dT%H):00:01.111111111Z sample 1
$(date +%Y-%m-%dT%H):00:02.222222222Z sample 2
$(date +%Y-%m-%dT%H):00:03.333333333Z sample 3
EOF
