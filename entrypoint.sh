#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

# Esperar a que la DB esté lista
echo ">>> Esperando a la base de datos..."
sleep 10

# Asegurarnos de que estamos en el directorio correcto
cd /app

echo ">>> Verificando variables de entorno..."
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL no está configurada"
    exit 1
fi

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Verificando conexión a la base de datos..."
python manage.py check

echo ">>> Creando extensión PostGIS..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    print('PostGIS instalado correctamente')
except Exception as e:
    print('Error al instalar PostGIS:', e)
    raise e
"

echo ">>> Aplicando migraciones..."
# Primero las migraciones base de Django
python manage.py migrate auth --noinput
python manage.py migrate contenttypes --noinput
python manage.py migrate admin --noinput
python manage.py migrate sessions --noinput

# Luego las migraciones de la aplicación
python manage.py migrate chbackend --noinput

# Finalmente, cualquier otra migración pendiente
python manage.py migrate --noinput

echo ">>> Creando superusuario..."
python manage.py create_admin

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --log-level debug \
    --workers 1


