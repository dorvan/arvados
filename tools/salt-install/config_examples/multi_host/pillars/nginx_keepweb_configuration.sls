---
# Copyright (C) The Arvados Authors. All rights reserved.
#
# SPDX-License-Identifier: AGPL-3.0

### NGINX
nginx:
  ### SERVER
  server:
    config:
      ### STREAMS
      http:
        upstream collections_downloads_upstream:
          - server: 'localhost:9002 fail_timeout=10s'

  servers:
    managed:
      ### DEFAULT
      arvados_collections_download_default:
        enabled: true
        overwrite: true
        config:
          - server:
            - server_name: '~^((.*--)?collections|download)\.__CLUSTER__\.__DOMAIN__'
            - listen:
              - 80
            - location /.well-known:
              - root: /var/www
            - location /:
              - return: '301 https://$host$request_uri'

      ### COLLECTIONS
      arvados_collections_ssl:
        enabled: true
        overwrite: true
        config:
          - server:
            - server_name: '~^(.*--)?collections\.__CLUSTER__\.__DOMAIN__'
            - listen:
              - __CONTROLLER_EXT_SSL_PORT__ http2 ssl
            - index: index.html index.htm
            - location /:
              - proxy_pass: 'http://collections_downloads_upstream'
              - proxy_read_timeout: 90
              - proxy_connect_timeout: 90
              - proxy_redirect: 'off'
              - proxy_set_header: X-Forwarded-Proto https
              - proxy_set_header: 'Host $http_host'
              - proxy_set_header: 'X-Real-IP $remote_addr'
              - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
              - proxy_buffering: 'off'
            - client_max_body_size: 0
            - proxy_http_version: '1.1'
            - proxy_request_buffering: 'off'
            - ssl_certificate: /etc/ssl/certs/wildcard.__DOMAIN__.crt
            - ssl_certificate_key: /etc/ssl/private/wildcard.__DOMAIN__.key
            - access_log: /var/log/nginx/collections.__DOMAIN__.access.log combined
            - error_log: /var/log/nginx/collections.__DOMAIN__.error.log

      ### DOWNLOAD
      arvados_download_ssl:
        enabled: true
        overwrite: true
        config:
          - server:
            - server_name: download.__DOMAIN__
            - listen:
              - __CONTROLLER_EXT_SSL_PORT__ http2 ssl
            - index: index.html index.htm
            - location /:
              - proxy_pass: 'http://collections_downloads_upstream'
              - proxy_read_timeout: 90
              - proxy_connect_timeout: 90
              - proxy_redirect: 'off'
              - proxy_set_header: X-Forwarded-Proto https
              - proxy_set_header: 'Host $http_host'
              - proxy_set_header: 'X-Real-IP $remote_addr'
              - proxy_set_header: 'X-Forwarded-For $proxy_add_x_forwarded_for'
              - proxy_buffering: 'off'
            - client_max_body_size: 0
            - proxy_http_version: '1.1'
            - proxy_request_buffering: 'off'
            - ssl_certificate: /etc/ssl/certs/wildcard.__DOMAIN__.crt
            - ssl_certificate_key: /etc/ssl/private/wildcard.__DOMAIN__.key
            - access_log: /var/log/nginx/download.__DOMAIN__.access.log combined
            - error_log: /var/log/nginx/download.__DOMAIN__.error.log
