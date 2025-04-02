#!/bin/bash

set -e  # Detener el script si hay algún error

echo "=== Iniciando entrypoint.sh ==="

# Función para mostrar mensajes de error
error_exit() {
    echo "ERROR: $1"
    exit 1
}

# Esperar a que la DB esté lista
echo ">>> Esperando a la base de datos..."
sleep 15

# Asegurarnos de que estamos en el directorio correcto
cd /app || error_exit "No se pudo cambiar al directorio /app"

# Mostrar variables de entorno (sin valores sensibles)
echo ">>> Variables de entorno:"
echo "DATABASE_URL configurada: $(if [ -n "$DATABASE_URL" ]; then echo "Sí"; else echo "No"; fi)"
echo "DJANGO_SETTINGS_MODULE: $DJANGO_SETTINGS_MODULE"
echo "DEBUG: $DEBUG"

# Verificar y configurar PostGIS
echo ">>> Verificando conexión a la base de datos y PostGIS..."
python manage.py shell -c "
from django.db import connection
cursor = connection.cursor()
try:
    # Verificar si podemos conectar
    cursor.execute('SELECT 1;')
    print('Conexión a la base de datos: OK')
    
    # Verificar/crear extensión PostGIS
    cursor.execute('CREATE EXTENSION IF NOT EXISTS postgis;')
    cursor.execute('SELECT PostGIS_version();')
    print('PostGIS Version:', cursor.fetchone()[0])
    
    # Listar todas las tablas
    cursor.execute(\"\"\"
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    \"\"\")
    print('\\nTablas existentes:')
    for table in cursor.fetchall():
        print(f'- {table[0]}')
except Exception as e:
    print('Error en la verificación de la base de datos:', e)
    raise e
"

# Recolectar archivos estáticos
echo ">>> Ejecutando collectstatic..."
python manage.py collectstatic --noinput || error_exit "Error en collectstatic"

# Verificar la configuración
echo ">>> Verificando configuración de Django..."
python manage.py check || error_exit "Error en la verificación de Django"

# Aplicar migraciones
echo ">>> Aplicando migraciones..."
echo "Migraciones disponibles:"
python manage.py showmigrations || error_exit "Error al listar migraciones"

echo "Aplicando migraciones en orden:"
python manage.py migrate auth --noinput || error_exit "Error en migraciones de auth"
python manage.py migrate contenttypes --noinput || error_exit "Error en migraciones de contenttypes"
python manage.py migrate sessions --noinput || error_exit "Error en migraciones de sessions"
python manage.py migrate admin --noinput || error_exit "Error en migraciones de admin"
python manage.py migrate --noinput || error_exit "Error en migraciones restantes"

echo ">>> Creando superusuario..."
python manage.py create_admin || error_exit "Error al crear superusuario"

echo "=== Configuración completada. Iniciando Gunicorn ==="

# Levantar Gunicorn en modo debug
export DJANGO_SETTINGS_MODULE=austral_ch_project.settings
export DJANGO_DEBUG=True

exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:8000 \
    --log-level debug \
    --timeout 120 \
    --workers 2


