from django.shortcuts import render
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.views.generic import TemplateView
from django.urls import reverse_lazy


def is_staff_or_superuser(user):
    """Check if user is staff or superuser"""
    return user.is_staff or user.is_superuser


class AdminDashboardView(LoginRequiredMixin, UserPassesTestMixin, TemplateView):
    """
    Main admin dashboard view with statistics
    GET /admin-dashboard/
    """
    template_name = 'analytics/dashboard.html'
    login_url = reverse_lazy('accounts:login')

    def test_func(self):
        """Check if user is staff or superuser"""
        return self.request.user.is_staff or self.request.user.is_superuser


class PermissionManagementView(LoginRequiredMixin, UserPassesTestMixin, TemplateView):
    """
    Permission management page - search and modify user permissions
    GET /admin-dashboard/permissions/
    """
    template_name = 'analytics/permissions.html'
    login_url = reverse_lazy('accounts:login')

    def test_func(self):
        """Check if user is staff or superuser"""
        return self.request.user.is_staff or self.request.user.is_superuser

    def get_context_data(self, **kwargs):
        """Add current user's role to context for permission filtering"""
        context = super().get_context_data(**kwargs)

        # Determine current user's role for frontend permission filtering
        user = self.request.user
        if user.is_prime:
            user_role = 'Prime'
        elif user.is_superuser:
            user_role = 'Superuser'
        elif user.is_staff:
            user_role = 'Staff'
        elif user.is_gold:
            user_role = 'GoldUser'
        else:
            user_role = 'User'

        context['user_role'] = user_role
        return context


class LotteryView(LoginRequiredMixin, UserPassesTestMixin, TemplateView):
    """
    Lottery page placeholder
    GET /admin-dashboard/lottery/
    """
    template_name = 'analytics/lottery.html'
    login_url = reverse_lazy('accounts:login')

    def test_func(self):
        """Check if user is Prime or Superuser (Staff는 접근 불가)"""
        return self.request.user.is_prime or self.request.user.is_superuser

    def get_context_data(self, **kwargs):
        """Add lottery statistics to context"""
        from lotto.models import NumberCombination, LottoDraw, OverlapStatistics, OverlapDetail
        from django.db.models import Count

        context = super().get_context_data(**kwargs)

        # 전체 회차 수
        total_draws = LottoDraw.objects.count()

        # 최신 회차 정보 가져오기
        latest_draw = LottoDraw.objects.order_by('-round_number').first()
        current_round = latest_draw.round_number if latest_draw else 0
        previous_round = current_round - 1 if current_round > 0 else 0

        # 중복 조합 찾기 (1등에서 동일한 6개 번호가 2번 이상 나온 경우)
        duplicates = NumberCombination.objects.filter(rank='1등') \
            .values('combination_hash') \
            .annotate(count=Count('id')) \
            .filter(count__gt=1)

        duplicate_count = duplicates.count()

        # 등수 쌍 레이블 정의 (1등 관련만 표시)
        pair_labels = {
            '1-2': '1등-2등 중복',
            '1-3': '1등-3등 중복',
            '1-4': '1등-4등 중복',
        }

        # 캐시된 중복 통계 가져오기 (현재 회차)
        overlap_stats = {}
        for stat in OverlapStatistics.objects.filter(rank_pair__in=['1-2', '1-3', '1-4']):
            overlap_stats[stat.rank_pair] = stat.overlap_count

        # 이전 회차 중복 통계 계산
        prev_overlap_stats = {}
        if previous_round > 0:
            for pair in ['1-2', '1-3', '1-4']:
                # 이전 회차까지의 중복 개수 (현재 회차 제외)
                prev_count = OverlapDetail.objects.filter(
                    rank_pair=pair,
                    first_rank_round__lte=previous_round,
                    second_rank_round__lte=previous_round
                ).count()
                prev_overlap_stats[pair] = prev_count

        # 각 등수 쌍별 상세 정보 가져오기 (1등 관련만)
        overlap_details = {}
        for pair in ['1-2', '1-3', '1-4']:
            details = OverlapDetail.objects.filter(rank_pair=pair).order_by('-first_rank_round')[:100]
            overlap_details[pair] = [
                {
                    'numbers': detail.numbers,
                    'first_rank': detail.first_rank,
                    'first_rank_round': detail.first_rank_round,
                    'first_rank_date': detail.first_rank_date,
                    'second_rank': detail.second_rank,
                    'second_rank_round': detail.second_rank_round,
                    'second_rank_date': detail.second_rank_date,
                }
                for detail in details
            ]

        context.update({
            'total_draws': total_draws,
            'duplicate_count': duplicate_count,
            'current_round': current_round,
            'previous_round': previous_round,
            'overlap_1_2': overlap_stats.get('1-2', 0),
            'overlap_1_3': overlap_stats.get('1-3', 0),
            'overlap_1_4': overlap_stats.get('1-4', 0),
            'prev_overlap_1_2': prev_overlap_stats.get('1-2', 0),
            'prev_overlap_1_3': prev_overlap_stats.get('1-3', 0),
            'prev_overlap_1_4': prev_overlap_stats.get('1-4', 0),
            'overlap_details': overlap_details,
        })

        return context
