[![Docker Hub; drnxloc/nginx-php-fpm](https://img.shields.io/badge/docker%20hub-drnxloc%2Fnginx--php--fpm-blue.svg?&logo=docker&style=for-the-badge)](https://hub.docker.com/r/drnxloc/nginx-php-fpm/) [![](https://badges.weareopensource.me/docker/pulls/drnxloc/nginx-php-fpm?style=for-the-badge)](https://hub.docker.com/r/drnxloc/nginx-php-fpm/) [![](https://img.shields.io/docker/image-size/drnxloc/nginx-php-fpm/latest?style=for-the-badge)](https://hub.docker.com/r/drnxloc/nginx-php-fpm/) [![nginx 1.26.0](https://img.shields.io/badge/nginx-1.26.0-brightgreen.svg?&logo=nginx&logoColor=white&style=for-the-badge)](https://nginx.org/en/CHANGES) [![php 8.3.7](https://img.shields.io/badge/php--fpm-8.3.7-blue.svg?&logo=php&logoColor=white&style=for-the-badge)](https://secure.php.net/releases/8_3_6.php) [![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?&style=for-the-badge)](https://github.com/drnxloc/nginx-php-fpm/blob/master/LICENSE)

## Introduction

This is a Dockerfile to build a debian based container image running nginx and php-fpm 8.3.x / 8.2.x / 8.1.x & Composer.

### Versioning

| Docker Tag | GitHub Release | Nginx Version | PHP Version | Debian Version | Composer |
| ---------- | -------------- | ------------- | ----------- | -------------- | -------- |
| latest     | master Branch  | 1.26.0        | 8.3.7       | bullseye       | 2.7.6    |
| php83      | php83 Branch   | 1.26.0        | 8.3.7       | bullseye       | 2.7.6    |
| php82      | php82 Branch   | 1.25.3        | 8.2.13      | bullseye       | 2.6.6    |
| php81      | php81 Branch   | 1.25.3        | 8.1.26      | bullseye       | 2.6.6    |

## Building from source

To build from source you need to clone the git repo and run docker build:

```
git clone https://github.com/drnxloc/nginx-php-fpm.git
cd nginx-php-fpm
```

followed by

```
docker build -t nginx-php-fpm:php83 . # PHP 8.3.x
```

## Pulling from Docker Hub

```
docker pull drnxloc/nginx-php-fpm:php83
```

## Running

To run the container:

```
sudo docker run -dp 80:80 drnxloc/nginx-php-fpm:php83
```

Default web root:

```
/usr/share/nginx/html
```

## Laravel

### Build Dockerfile

```docker
# Laravel Schedule
RUN crontab -l | { cat; echo "* * * * * php /var/www/laravel/artisan schedule:run >> /dev/null 2>&1"; } | crontab -
```
