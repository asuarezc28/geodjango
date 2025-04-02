#!/bin/bash

# Esperar a que la DB esté lista (opcional)
echo "Esperando a la base de datos..."
sleep 5

# Ejecutar migraciones y crear superusuario
python manage.py migrate
python manage.py create_admin

# Recolectar archivos estáticos (para que funcione el admin en producción)
python manage.py collectstatic --noinput

# Luego levantar gunicorn
exec gunicorn austral_ch_project.wsgi:application --bind 0.0.0.0:8000


#!/bin/bash

echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput

echo ">>> Aplicando migraciones..."
python manage.py migrate
python manage.py create_admin

echo ">>> Levantando Gunicorn..."
exec gunicorn austral_ch_project.wsgi:application --bind 0.0.0.0:8000


echo "== Ejecutando servidor con DEBUG =="
export DJANGO_DEBUG=True
exec gunicorn austral_ch_project.wsgi:application --bind 0.0.0.0:8000 --log-level debug
