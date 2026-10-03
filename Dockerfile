FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 nginx openssl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

RUN mkdir -p /etc/ssl/private /etc/ssl/certs \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/my-app.key \
        -out /etc/ssl/certs/my-app.crt \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
    && chmod 600 /etc/ssl/private/my-app.key

WORKDIR /var/www

COPY script.sh /usr/local/bin/script.sh
COPY nginx-container.conf /etc/nginx/conf.d/app.conf

RUN chmod +x /usr/local/bin/script.sh && nginx -t

CMD ["/bin/bash", "-c", "/usr/local/bin/script.sh & python3 -u -m http.server 8080 --bind 0.0.0.0 --directory /var/www & exec nginx -g 'daemon off;'"]