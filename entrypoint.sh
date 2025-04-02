#!/bin/bash

# Esperar a que la DB esté lista (opcional)
echo "Esperando a la base de datos..."
sleep 5

# Ejecutar migraciones y crear superusuario
python manage.py migrate
python manage.py create_admin

# Luego levantar gunicorn
exec gunicorn austral_ch_project.wsgi:application --bind 0.0.0.0:8000
