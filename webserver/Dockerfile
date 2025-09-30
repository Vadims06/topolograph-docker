FROM nginx:latest

LABEL MAINTAINER="Vadim <admin@topolograph.com>"

# Install envsubst (for runtime templating) and do minimal cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends gettext-base && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p /run/nginx && \
    rm -f /etc/nginx/conf.d/default.conf && \
    rm -rf /var/lib/apt/lists/*

COPY templates/app.conf.template /etc/nginx/conf.d/app.conf.template
COPY start-nginx.sh /start-nginx.sh
RUN chmod +x /start-nginx.sh

EXPOSE 8080
CMD ["/start-nginx.sh"]
