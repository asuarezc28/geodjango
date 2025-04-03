from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Crea un superusuario admin si no existe'

    def handle(self, *args, **kwargs):
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser(
                'admin',
                'admin@example.com',
                'admin12345'
            )
            self.stdout.write('Superusuario creado exitosamente')
        else:
            self.stdout.write('El superusuario ya existe')
