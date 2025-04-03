#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

# Esperar a que la DB esté lista
echo ">>> Esperando a la base de datos..."
sleep 15

# Asegurarnos de que estamos en el directorio correcto
cd /app

echo ">>> Verificando variables de entorno..."
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL no está configurada"
    exit 1
fi

echo ">>> Verificando conexión a la base de datos..."
until python manage.py shell -c "
from django.db import connection
try:
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    print('Conexión a la base de datos exitosa')
    exit(0)
except Exception as e:
    print('Error conectando a la base de datos:', e)
    exit(1)
"
do
    echo ">>> Esperando conexión a la base de datos..."
    sleep 5
done

echo ">>> Limpiando migraciones existentes..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('DROP SCHEMA public CASCADE;')
    cursor.execute('CREATE SCHEMA public;')
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    print('Schema reiniciado correctamente y PostGIS instalado')
except Exception as e:
    print('Error al reiniciar schema:', e)
    exit(1)
"

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones iniciales..."
# Primero las migraciones base de Django
python manage.py migrate auth --fake-initial
python manage.py migrate contenttypes --fake-initial
python manage.py migrate admin --fake-initial
python manage.py migrate sessions --fake-initial

# Ahora las migraciones reales
python manage.py migrate --noinput

echo ">>> Verificando tablas creadas..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\';')
tables = cursor.fetchall()
print('Tablas en la base de datos:', [table[0] for table in tables])
"

echo ">>> Creando superusuario..."
python manage.py create_admin

echo ">>> Esperando 5 segundos antes de iniciar Gunicorn..."
sleep 5

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --log-level debug \
    --workers 1 \
    --timeout 120


