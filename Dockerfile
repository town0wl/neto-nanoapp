FROM nginx:1.22.1-alpine

RUN rm /etc/nginx/conf.d/default.conf
COPY nanoapp.conf /etc/nginx/conf.d/nanoapp.conf
COPY content /usr/share/nginx/html