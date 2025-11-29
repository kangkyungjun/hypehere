from django.core.management.base import BaseCommand
from analytics.api_views import update_all_strategy_statistics


class Command(BaseCommand):
    help = '전략별 확률 통계 업데이트'

    def handle(self, *args, **options):
        self.stdout.write('=' * 60)
        self.stdout.write('전략별 확률 통계 계산 중...')
        self.stdout.write('=' * 60)
        
        try:
            result = update_all_strategy_statistics()
            
            if result:
                self.stdout.write(self.style.SUCCESS('\n✅ 통계 업데이트 완료!'))
                
                # Show results
                from lotto.models import StrategyStatistics
                stats = StrategyStatistics.objects.all().order_by('strategy_type')
                
                self.stdout.write('\n현재 통계:')
                self.stdout.write('-' * 60)
                for stat in stats:
                    self.stdout.write(f'\n{stat.strategy_type}:')
                    self.stdout.write(f'  회차: {stat.round_number}')
                    self.stdout.write(f'  전체 조합: {stat.total_theoretical:,}')
                    self.stdout.write(f'  제외됨: {stat.excluded_count:,}')
                    self.stdout.write(f'  남은 조합: {stat.remaining_count:,}')
                    self.stdout.write(f'  확률: 1/{stat.remaining_count:,} ({stat.probability * 100:.6f}%)')
                    self.stdout.write(f'  개선 배수: {stat.improvement_ratio:.1f}배')
                
                self.stdout.write('\n' + '=' * 60)
            else:
                self.stdout.write(self.style.WARNING('\n⚠️  회차 데이터가 없습니다'))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'\n❌ 에러 발생: {str(e)}'))
            raise
