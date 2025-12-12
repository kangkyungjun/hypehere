from django.urls import path
from . import views

# Conditionally import api_views (only if file exists - local development only)
import os
from django.conf import settings

try:
    if os.path.exists(os.path.join(settings.BASE_DIR, 'analytics', 'api_views.py')):
        from . import api_views
        HAS_API_VIEWS = True
    else:
        HAS_API_VIEWS = False
except ImportError:
    HAS_API_VIEWS = False

app_name = 'analytics'

urlpatterns = [
    # Dashboard views
    path('', views.AdminDashboardView.as_view(), name='dashboard'),
    path('permissions/', views.PermissionManagementView.as_view(), name='permissions'),
]

# Add lottery views only if lotto app is available
if HAS_API_VIEWS:
    urlpatterns += [
        # Lottery views (local only - requires lotto app)
        path('lottery/', views.LotteryView.as_view(), name='lottery'),
        path('lottery/edit/', views.LotteryEditView.as_view(), name='lottery_edit'),

        # API endpoints
        path('api/stats/', api_views.dashboard_stats_api, name='api_stats'),
        path('api/users/search/', api_views.search_users_api, name='api_user_search'),
        path('api/users/<int:user_id>/permissions/', api_views.update_user_permissions_api, name='api_update_permissions'),

        # Lottery API endpoints (local only - requires api_views.py and lotto app)
        path('lottery/check-number/', api_views.check_lotto_number_api, name='lottery_check_number'),
        path('lottery/save-number/', api_views.save_lotto_number_api, name='lottery_save_number'),
        path('lottery/my-numbers/', api_views.my_lotto_numbers_api, name='lottery_my_numbers'),
        path('lottery/my-numbers/<int:number_id>/', api_views.delete_lotto_number_api, name='lottery_delete_number'),
        path('lottery/latest-round/', api_views.get_latest_round_api, name='lottery_latest_round'),
        path('lottery/save-draw/', api_views.save_draw_api, name='lottery_save_draw'),
        path('lottery/generate-smart-numbers/', api_views.generate_smart_numbers_api, name='lottery_generate_smart'),
        path('lottery/generate-strategy1/', api_views.generate_strategy1_numbers_api, name='lottery_generate_strategy1'),
        path('lottery/generate-strategy2/', api_views.generate_strategy2_numbers_api, name='lottery_generate_strategy2'),
        path('lottery/generate-strategy3/', api_views.generate_strategy3_numbers_api, name='lottery_generate_strategy3'),
        path('lottery/generate-strategy4/', api_views.generate_strategy4_numbers_api, name='lottery_generate_strategy4'),
        path('lottery/generate-integrated/', api_views.generate_strategy5_numbers_api, name='lottery_generate_integrated'),
        path('lottery/probability-stats/', api_views.probability_stats_api, name='lottery_probability_stats'),
        path('lottery/strategy-probability/<str:strategy_type>/', api_views.get_strategy_probability_api, name='lottery_strategy_probability'),

        # Lottery Management API endpoints (local only - requires api_views.py and lotto app)
        path('api/admin/lottery/recent-draws/', api_views.get_recent_draws_api, name='api_lottery_recent_draws'),
        path('api/admin/lottery/draws/<int:round_number>/', api_views.delete_draw_api, name='api_lottery_delete_draw'),
    ]
else:
    # Minimal API endpoints for AWS (without lottery functionality)
    from django.http import JsonResponse
    from django.views.decorators.http import require_http_methods

    @require_http_methods(["GET"])
    def dashboard_stats_api_stub(request):
        return JsonResponse({
            'visitors': {'today': 0, 'yesterday': 0, 'week': 0, 'month': 0},
            'new_users': {'today': 0, 'yesterday': 0, 'week': 0, 'month': 0, 'total': 0},
            'active_users': {'today': 0, 'yesterday': 0, 'week_average': 0},
            'posts': {'today': 0, 'yesterday': 0, 'week': 0, 'month': 0, 'total': 0},
            'anonymous_chat': {
                'users': {'today': 0, 'week': 0, 'month': 0, 'total': 0},
                'average_per_user': {'daily': '0', 'weekly': '0', 'monthly': '0'}
            }
        })

    urlpatterns += [
        path('api/stats/', dashboard_stats_api_stub, name='api_stats'),
    ]
