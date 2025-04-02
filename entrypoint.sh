#!/bin/bash

# Esperar a que la DB esté lista (opcional)
echo "Esperando a la base de datos..."
sleep 5

# Recolectar archivos estáticos (para que funcione el admin en producción)
echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

# Aplicar migraciones y crear superusuario
echo ">>> Aplicando migraciones..."
python manage.py migrate
python manage.py create_admin

# Levantar Gunicorn en modo debug para registrar errores
echo "== Levantando Gunicorn =="
export DJANGO_SETTINGS_MODULE=austral_ch_project.settings
export DJANGO_DEBUG=True

exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:8000 \
    --log-level debug


