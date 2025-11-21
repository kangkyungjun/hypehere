from django.urls import path
from . import api_views, views

app_name = 'learning'

urlpatterns = [
    # Situation-Based Learning Views
    path('situations/', views.SituationCategoryListView.as_view(), name='situation_categories'),
    path('situations/<str:category_code>/', views.SituationLessonListView.as_view(), name='situation_lessons'),
    path('situations/<str:category_code>/<slug:lesson_slug>/', views.SituationLessonDetailView.as_view(), name='situation_detail'),

    # Situation Expression API (Admin only)
    path('api/expressions/', api_views.SituationExpressionCreateView.as_view(), name='api_expression_create'),
    path('api/expressions/<int:expression_id>/', api_views.SituationExpressionUpdateView.as_view(), name='api_expression_update'),
    path('api/expressions/<int:expression_id>/delete/', api_views.SituationExpressionDeleteView.as_view(), name='api_expression_delete'),
    path('api/expressions/bookmarked/', api_views.BookmarkedExpressionsView.as_view(), name='api_bookmarked_expressions'),
]
