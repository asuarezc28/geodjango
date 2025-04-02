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
python << END
import sys
import time
import psycopg2
from urllib.parse import urlparse
import os

# Obtener DATABASE_URL
db_url = os.getenv('DATABASE_URL')
if not db_url:
    print('ERROR: DATABASE_URL no está configurada')
    sys.exit(1)

# Parsear DATABASE_URL
url = urlparse(db_url)
dbname = url.path[1:]
user = url.username
password = url.password
host = url.hostname
port = url.port or 5432

# Intentar conectar
for i in range(10):
    try:
        print(f'Intento {i+1} de conectar a la base de datos...')
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port,
            sslmode='require'
        )
        conn.close()
        print('Conexión exitosa a la base de datos!')
        sys.exit(0)
    except psycopg2.OperationalError as e:
        print(f'No se pudo conectar: {e}')
        time.sleep(3)

print('No se pudo conectar a la base de datos después de varios intentos')
sys.exit(1)
END

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
python manage.py migrate --noinput || error_exit "Error en migraciones"

echo ">>> Creando superusuario..."
python manage.py create_admin || error_exit "Error al crear superusuario"

echo "=== Configuración completada. Iniciando Gunicorn ==="

# Levantar Gunicorn en modo debug
export DJANGO_SETTINGS_MODULE=austral_ch_project.settings
export DJANGO_DEBUG=True

exec gunicorn austral_ch_project.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --log-level debug \
    --timeout 120 \
    --workers 1


