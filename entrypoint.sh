#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

cd /app

echo ">>> Verificando variables de entorno..."
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL no está configurada"
    exit 1
fi

echo ">>> Esperando a la base de datos..."
sleep 15

echo ">>> Verificando conexión a la base de datos..."
python manage.py shell -c "
from django.db import connection
try:
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    print('Conexión a la base de datos OK')
except Exception as e:
    print('Error DB:', e)
    exit(1)
"

echo ">>> Limpiando base de datos..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('DROP SCHEMA public CASCADE;')
    cursor.execute('CREATE SCHEMA public;')
    print('Schema reiniciado correctamente')
except Exception as e:
    print('Error al reiniciar schema:', e)
    exit(1)
"

echo ">>> Instalando PostGIS..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    print('PostGIS instalado correctamente')
except Exception as e:
    print('Error al instalar PostGIS:', e)
    exit(1)
"

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones..."
# Primero las migraciones base
python manage.py migrate auth --fake-initial
python manage.py migrate contenttypes --fake-initial
python manage.py migrate admin --fake-initial
python manage.py migrate sessions --fake-initial

# Luego todas las migraciones
python manage.py migrate --fake-initial

echo ">>> Verificando tablas..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute('''
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
''')
tables = cursor.fetchall()
print('Tablas creadas:', [t[0] for t in tables])

if not any('auth_user' in t[0] for t in tables):
    print('ERROR: Tabla auth_user no encontrada')
    exit(1)
"

echo ">>> Creando superusuario..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin12345')
    print('Superusuario creado')
"

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --log-level debug \
    --workers 1 \
    --timeout 120