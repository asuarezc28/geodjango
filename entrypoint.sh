#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

# Esperar a que la DB esté lista
echo ">>> Esperando a la base de datos..."
sleep 10

cd /app

echo ">>> Verificando variables de entorno..."
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL no está configurada"
    exit 1
fi

echo ">>> Probing conexión a la base de datos..."
until python manage.py shell -c "
from django.db import connection
try:
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    print('Conexión a la base de datos OK')
except Exception as e:
    print('Error DB:', e)
    exit(1)
"
do
    echo ">>> Reintentando conexión..."
    sleep 5
done

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones iniciales..."
python manage.py migrate auth --fake-initial
python manage.py migrate contenttypes --fake-initial
python manage.py migrate admin --fake-initial
python manage.py migrate sessions --fake-initial

echo ">>> Aplicando migraciones generales..."
python manage.py migrate --noinput

echo ">>> Tablas actuales:"
python manage.py dbshell -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

echo ">>> Creando superusuario si no existe..."
python manage.py create_admin

echo ">>> Arrancando Gunicorn..."
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --log-level debug \
    --workers 2 \
    --timeout 120