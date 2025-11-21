from django.core.management.base import BaseCommand
from chat.models import OpenChatRoom


class Command(BaseCommand):
    help = 'Create default open chat rooms for major countries'

    # 30 major countries with format: (country_code, English name, Local name)
    MAJOR_COUNTRIES = [
        ('KR', 'Korea', '대한민국'),
        ('US', 'USA', 'United States'),
        ('JP', 'Japan', '日本'),
        ('CN', 'China', '中国'),
        ('GB', 'UK', 'United Kingdom'),
        ('FR', 'France', 'France'),
        ('DE', 'Germany', 'Deutschland'),
        ('ES', 'Spain', 'España'),
        ('IT', 'Italy', 'Italia'),
        ('RU', 'Russia', 'Россия'),
        ('BR', 'Brazil', 'Brasil'),
        ('MX', 'Mexico', 'México'),
        ('CA', 'Canada', 'Canada'),
        ('AU', 'Australia', 'Australia'),
        ('IN', 'India', 'भारत'),
        ('TH', 'Thailand', 'ประเทศไทย'),
        ('VN', 'Vietnam', 'Việt Nam'),
        ('PH', 'Philippines', 'Pilipinas'),
        ('ID', 'Indonesia', 'Indonesia'),
        ('SA', 'Saudi Arabia', 'السعودية'),
        ('NL', 'Netherlands', 'Nederland'),
        ('SE', 'Sweden', 'Sverige'),
        ('CH', 'Switzerland', 'Schweiz'),
        ('PL', 'Poland', 'Polska'),
        ('TR', 'Turkey', 'Türkiye'),
        ('AR', 'Argentina', 'Argentina'),
        ('CL', 'Chile', 'Chile'),
        ('CO', 'Colombia', 'Colombia'),
        ('ZA', 'South Africa', 'South Africa'),
        ('EG', 'Egypt', 'مصر'),
    ]

    # Flag emojis for countries (using Unicode regional indicator symbols)
    FLAG_EMOJIS = {
        'KR': '🇰🇷', 'US': '🇺🇸', 'JP': '🇯🇵', 'CN': '🇨🇳', 'GB': '🇬🇧',
        'FR': '🇫🇷', 'DE': '🇩🇪', 'ES': '🇪🇸', 'IT': '🇮🇹', 'RU': '🇷🇺',
        'BR': '🇧🇷', 'MX': '🇲🇽', 'CA': '🇨🇦', 'AU': '🇦🇺', 'IN': '🇮🇳',
        'TH': '🇹🇭', 'VN': '🇻🇳', 'PH': '🇵🇭', 'ID': '🇮🇩', 'SA': '🇸🇦',
        'NL': '🇳🇱', 'SE': '🇸🇪', 'CH': '🇨🇭', 'PL': '🇵🇱', 'TR': '🇹🇷',
        'AR': '🇦🇷', 'CL': '🇨🇱', 'CO': '🇨🇴', 'ZA': '🇿🇦', 'EG': '🇪🇬',
    }

    def handle(self, *args, **options):
        created_count = 0
        skipped_count = 0

        self.stdout.write('Creating default chat rooms for major countries...\n')

        for country_code, english_name, local_name in self.MAJOR_COUNTRIES:
            flag = self.FLAG_EMOJIS.get(country_code, '🌍')
            room_name = f"{flag} {english_name} {local_name}"

            # Check if room already exists
            if OpenChatRoom.objects.filter(country_code=country_code).exists():
                self.stdout.write(
                    self.style.WARNING(f'  ⚠ Room already exists: {room_name}')
                )
                skipped_count += 1
                continue

            # Create the room
            room = OpenChatRoom.objects.create(
                name=room_name,
                country_code=country_code,
                category='language',  # Default to language exchange
                is_active=True,
                max_participants=100
            )

            self.stdout.write(
                self.style.SUCCESS(f'  ✓ Created: {room_name}')
            )
            created_count += 1

        # Summary
        self.stdout.write('\n' + '='*60)
        self.stdout.write(
            self.style.SUCCESS(f'✓ Created {created_count} new rooms')
        )
        if skipped_count > 0:
            self.stdout.write(
                self.style.WARNING(f'⚠ Skipped {skipped_count} existing rooms')
            )
        self.stdout.write(
            f'Total rooms in database: {OpenChatRoom.objects.count()}'
        )
        self.stdout.write('='*60 + '\n')
