FROM php:8.1-fpm

ENV HOST_GID=1000 \
    HOST_UID=1000

# Tambahkan user dengan UID dan GID yang sama
RUN groupmod -g $HOST_GID www-data && \
    usermod -u $HOST_UID www-data

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    libonig-dev \
    libzip-dev \
    jpegoptim optipng pngquant gifsicle \
    ca-certificates \
    curl

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/
RUN docker-php-ext-install gd
RUN pecl install -o -f redis &&  rm -rf /tmp/pear && docker-php-ext-enable redis

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Pindah ke folder aplikasi
WORKDIR /var/www

# Copy seluruh project (agar tidak overwrite hasil composer install nanti)
COPY . /var/www/

# Ubah kepemilikan file
RUN chown -R www-data:www-data /var/www

# Pastikan direktori yang butuh izin dapat diakses
RUN chmod -R 775 /var/www/storage /var/www/bootstrap/cache /var/www/vendor

# Ganti user ke www-data
USER www-data

# Expose port 9000
EXPOSE 9000

# Jalankan Composer Install saat container berjalan
CMD ["sh", "-c", "composer install --no-interaction --no-dev --optimize-autoloader && php-fpm"]