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

echo ">>> Creando migraciones iniciales..."
python manage.py makemigrations contenttypes
python manage.py makemigrations auth
python manage.py makemigrations admin
python manage.py makemigrations sessions
python manage.py makemigrations chbackend

echo ">>> Aplicando migraciones en orden..."
python manage.py migrate contenttypes --noinput
python manage.py migrate auth --noinput
python manage.py migrate admin --noinput
python manage.py migrate sessions --noinput
python manage.py migrate chbackend --noinput

echo ">>> Verificando tablas creadas..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\';')
tables = cursor.fetchall()
table_names = [table[0] for table in tables]
print('Tablas en la base de datos:', table_names)

required_tables = ['auth_user', 'django_admin_log', 'auth_permission', 'django_content_type']
missing_tables = [table for table in required_tables if table not in table_names]

if missing_tables:
    print('ERROR: Faltan las siguientes tablas:', missing_tables)
    exit(1)
print('Todas las tablas requeridas están presentes')
"

echo ">>> Creando superusuario..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
try:
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser('admin', 'admin@example.com', 'admin12345')
        print('Superusuario creado exitosamente')
    else:
        print('El superusuario ya existe')
except Exception as e:
    print('Error al crear superusuario:', e)
    exit(1)
"

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --log-level debug \
    --workers 1 \
    --timeout 120