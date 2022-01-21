sed -i "s/80/$0/g" /etc/nginx/conf.d/default.conf
echo "port $0" > /usr/share/nginx/html/index.html
nginx -g 'daemon off;'
