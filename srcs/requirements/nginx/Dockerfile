FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=CZ/ST=Prague/L=Prague/O=42 Prague/OU=1337/CN=${DOMAIN_NAME}"

CMD ["nginx", "-g", "daemon off;"]