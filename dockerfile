FROM php:8.2-fpm

# Instala dependências
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Define o diretório da aplicação como /app
WORKDIR /app

# Copia tudo para /app
COPY . /app

# Ajusta permissões
RUN chown -R www-data:www-data /app

EXPOSE 9000
CMD ["php-fpm"]

