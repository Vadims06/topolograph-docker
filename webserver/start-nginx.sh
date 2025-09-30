#!/bin/sh

# Substitute environment variables in nginx config
envsubst '${TOPOLOGRAPH_PORT}' < /etc/nginx/conf.d/app.conf.template > /etc/nginx/conf.d/app.conf

# Start nginx
nginx -g "daemon off;"
