# Dockerfile para Django con GeoDjango y PostGIS
FROM python:3.10-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Establecer entorno no interactivo
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instalar dependencias del sistema necesarias para GeoDjango
RUN apt-get update && apt-get install -y \
    binutils libproj-dev gdal-bin libgdal-dev \
    libgeos-dev gcc python3-dev musl-dev \
    netcat-openbsd tzdata && \
    rm -rf /var/lib/apt/lists/*

# Configurar zona horaria por defecto (UTC)
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copiar todo el código fuente
COPY . .

# Copiar y dar permisos al entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Usar el script como entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]







