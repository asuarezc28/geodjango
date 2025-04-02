#!/bin/bash

set -e  # Detener el script si hay algún error

# Esperar a que la DB esté lista
echo "Esperando a la base de datos..."
sleep 15

# Asegurarnos de que estamos en el directorio correcto
cd /app

# Mostrar el directorio actual y su contenido
echo "Directorio actual:"
pwd
echo "Contenido del directorio:"
ls -la

# Verificar y configurar PostGIS
echo ">>> Verificando y configurando PostGIS..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    cursor.execute('SELECT PostGIS_version();')
    print('PostGIS Version:', cursor.fetchone()[0])
except Exception as e:
    print('Error al configurar PostGIS:', e)
"

# Recolectar archivos estáticos
echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

# Verificar la configuración de la base de datos
echo ">>> Verificando conexión a la base de datos..."
python manage.py check

# Aplicar migraciones y crear superusuario
echo ">>> Listando migraciones..."
python manage.py showmigrations

echo ">>> Aplicando migraciones..."
# Primero las migraciones de auth
python manage.py migrate auth --noinput
# Luego las migraciones de contenttypes
python manage.py migrate contenttypes --noinput
# Finalmente todas las demás
python manage.py migrate --noinput

echo ">>> Creando superusuario..."
python manage.py create_admin

# Levantar Gunicorn en modo debug
echo "== Levantando Gunicorn =="
export DJANGO_SETTINGS_MODULE=austral_ch_project.settings
export DJANGO_DEBUG=True

exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:8000 \
    --log-level debug \
    --timeout 120


