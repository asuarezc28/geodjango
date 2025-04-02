#!/bin/bash

# Esperar a que la DB esté lista
echo "Esperando a la base de datos..."
sleep 15  # Aumentamos el tiempo de espera

# Asegurarnos de que estamos en el directorio correcto
cd /app

# Recolectar archivos estáticos
echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

# Aplicar migraciones y crear superusuario
echo ">>> Aplicando migraciones..."
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python manage.py create_admin

# Levantar Gunicorn en modo debug
echo "== Levantando Gunicorn =="
export DJANGO_SETTINGS_MODULE=austral_ch_project.settings
export DJANGO_DEBUG=True

exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:8000 \
    --log-level debug


