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

echo ">>> Creando tablas manualmente..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()

# Crear tabla auth_user
cursor.execute('''
CREATE TABLE auth_user (
    id serial PRIMARY KEY,
    password varchar(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username varchar(150) NOT NULL UNIQUE,
    first_name varchar(150) NOT NULL,
    last_name varchar(150) NOT NULL,
    email varchar(254) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);
''')

# Crear tabla django_content_type
cursor.execute('''
CREATE TABLE django_content_type (
    id serial PRIMARY KEY,
    app_label varchar(100) NOT NULL,
    model varchar(100) NOT NULL,
    CONSTRAINT django_content_type_app_label_model_key UNIQUE (app_label, model)
);
''')

# Crear tabla auth_permission
cursor.execute('''
CREATE TABLE auth_permission (
    id serial PRIMARY KEY,
    name varchar(255) NOT NULL,
    content_type_id integer NOT NULL REFERENCES django_content_type(id),
    codename varchar(100) NOT NULL,
    CONSTRAINT auth_permission_content_type_id_codename_key UNIQUE (content_type_id, codename)
);
''')

print('Tablas base creadas correctamente')
"

echo ">>> Aplicando migraciones restantes..."
python manage.py migrate --no-input

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