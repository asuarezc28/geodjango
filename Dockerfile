# Dockerfile para Django con GeoDjango y PostGIS
FROM python:3.10

# Establecer el directorio de trabajo
WORKDIR /app

# Establecer entorno no interactivo y prevenir errores por tiempo
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema necesarias para GeoDjango
RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update && \
    apt-get install -y \
    binutils libproj-dev gdal-bin libgdal-dev \
    libgeos-dev gcc python3-dev musl-dev \
    netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Establecer variables de entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Copiar archivos
COPY requirements.txt requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .

# Copiar entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Usar el entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]



