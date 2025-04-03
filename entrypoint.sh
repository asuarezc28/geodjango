#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

# Esperar a que la DB esté lista
echo ">>> Esperando a la base de datos..."
sleep 15

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
    print('Conexión a la base de datos OK')
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    print('PostGIS instalado correctamente')
    exit(0)
except Exception as e:
    print('Error DB:', e)
    exit(1)
"
do
    echo ">>> Reintentando conexión..."
    sleep 5
done

echo ">>> Limpiando base de datos..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('DROP SCHEMA public CASCADE;')
    cursor.execute('CREATE SCHEMA public;')
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    print('Schema reiniciado correctamente')
except Exception as e:
    print('Error al reiniciar schema:', e)
    exit(1)
"

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Creando y aplicando migraciones..."
python manage.py makemigrations
python manage.py migrate

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

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --log-level debug \
    --workers 1 \
    --timeout 120