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
python manage.py shell -c "
from django.db import connection
try:
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    print('Conexión a la base de datos exitosa')
except Exception as e:
    print('Error conectando a la base de datos:', e)
    exit(1)
"

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones iniciales..."
# Primero contenttypes (debe ser la primera)
echo ">>> Aplicando migraciones de contenttypes..."
python manage.py migrate contenttypes --noinput

# Luego auth (depende de contenttypes)
echo ">>> Aplicando migraciones de auth..."
python manage.py migrate auth --noinput

# Resto de las migraciones de Django
echo ">>> Aplicando migraciones de admin..."
python manage.py migrate admin --noinput
echo ">>> Aplicando migraciones de sessions..."
python manage.py migrate sessions --noinput

# Verificar que las tablas base se crearon
echo ">>> Verificando tablas creadas..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
cursor.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = \'public\' AND table_name LIKE \'auth_%\';')
tables = cursor.fetchall()
print('Tablas de auth en la base de datos:', [table[0] for table in tables])
if not any('auth_user' in table[0] for table in tables):
    print('ERROR: La tabla auth_user no se creó correctamente')
    exit(1)
print('Tablas de auth creadas correctamente')
"

echo ">>> Creando superusuario..."
python manage.py create_admin

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --log-level debug \
    --workers 1


