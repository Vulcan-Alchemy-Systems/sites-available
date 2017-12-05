set_real_ip_from 35.203.134.1;
set_real_ip_from 127.0.0.1;

map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream vulcanalchemyonline.com {
    server 127.0.0.1:3010;
}

server {
   listen 80;
   server_name www.vulcanalchemyonline.com;
   access_log  /var/log/nginx/vulcanalchemyonline.com.log;
   error_log  /var/log/nginx/vulcanalchemyonline.com.log error;
   
   location / {
      proxy_pass  http://vulcanalchemyonline.com;
      # proxy_http_version 1.1;
      proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
      proxy_set_header Upgrade $http_upgrade; # allow websockets
      proxy_set_header Connection $connection_upgrade;
      proxy_redirect off;
      proxy_buffering off;
      proxy_set_header        Host            $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $remote_addr;

      # this setting allows the browser to cache the application in a way compatible with Meteor
      # on every applicaiton update the name of CSS and JS file is different, so they can be cache infinitely (here: 30 days)
      # the root path (/) MUST NOT be cached
      if ($uri != '/') {
          expires 30d;
      }
   }
   location ~ /.well-known {
      allow all;
   }
}



