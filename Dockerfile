# Dockerfile para Django con GeoDjango y PostGIS
FROM python:3.10-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instalar dependencias del sistema necesarias para GeoDjango
RUN apt-get update && apt-get install -y \
    binutils libproj-dev gdal-bin libgdal-dev \
    libgeos-dev gcc python3-dev musl-dev \
    netcat-openbsd tzdata && \
    rm -rf /var/lib/apt/lists/*

# Establecer zona horaria (opcional pero recomendable)
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el código del proyecto
COPY . .

# Copiar entrypoint y dar permisos
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Entrypoint que arranca todo (migraciones, collectstatic, gunicorn...)
ENTRYPOINT ["/app/entrypoint.sh"]







