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

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones..."
python manage.py migrate --noinput

echo ">>> Creando superusuario..."
python manage.py create_admin

echo "=== Iniciando Gunicorn ==="
exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --log-level debug \
    --workers 1


