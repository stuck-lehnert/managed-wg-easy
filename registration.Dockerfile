FROM php:8.2-apache

COPY ./src/issue.php /var/www/html/
RUN chown -R www-data:www-data /var/www

