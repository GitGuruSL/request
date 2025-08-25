# Manual Nginx HTTPS Configuration Guide

## If Certbot fails, here's manual setup:

### 1. Generate Self-Signed Certificate (for testing):
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/api.alphabet.lk.key \
  -out /etc/ssl/certs/api.alphabet.lk.crt \
  -subj "/C=LK/ST=Central/L=Kandy/O=Request Technologies/CN=api.alphabet.lk"
```

### 2. Update Nginx Configuration:
```bash
sudo nano /etc/nginx/sites-available/default
```

Replace content with:
```nginx
server {
    listen 80;
    server_name api.alphabet.lk;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name api.alphabet.lk;
    
    ssl_certificate /etc/ssl/certs/api.alphabet.lk.crt;
    ssl_certificate_key /etc/ssl/private/api.alphabet.lk.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 3. Test and Restart:
```bash
sudo nginx -t
sudo systemctl restart nginx
```
