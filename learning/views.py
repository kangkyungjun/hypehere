from django.shortcuts import get_object_or_404
from django.views.generic import ListView, DetailView

from .models import SituationCategory, SituationLesson, SituationExpression


# ============================================================================
# Situation-Based Learning Views
# ============================================================================

class SituationCategoryListView(ListView):
    """
    Display all situation categories for a specific language
    """
    model = SituationCategory
    template_name = 'learning/situation_categories.html'
    context_object_name = 'categories'

    def get_queryset(self):
        """Get active categories"""
        return SituationCategory.objects.filter(is_active=True).order_by('order')

    def get_context_data(self, **kwargs):
        """Add language and lesson counts"""
        context = super().get_context_data(**kwargs)
        context['selected_language'] = self.request.GET.get('language', 'EN')

        # Add lesson count per category for selected language
        for category in context['categories']:
            category.lesson_count = category.lessons.filter(
                language=context['selected_language'],
                is_published=True
            ).count()

        return context


class SituationLessonListView(ListView):
    """
    Display lessons in a specific situation category
    """
    model = SituationLesson
    template_name = 'learning/situation_lessons.html'
    context_object_name = 'lessons'

    def get_queryset(self):
        """Filter by category and language"""
        category_code = self.kwargs.get('category_code')
        language = self.request.GET.get('language', 'EN')

        return SituationLesson.objects.filter(
            category__code=category_code,
            language=language,
            is_published=True
        ).select_related('category').order_by('order', 'title_ko')

    def get_context_data(self, **kwargs):
        """Add category info"""
        context = super().get_context_data(**kwargs)
        category_code = self.kwargs.get('category_code')
        context['category'] = get_object_or_404(
            SituationCategory,
            code=category_code
        )
        context['selected_language'] = self.request.GET.get('language', 'EN')
        return context


class SituationLessonDetailView(DetailView):
    """
    Display lesson with all expressions and vocabulary
    """
    model = SituationLesson
    template_name = 'learning/situation_detail.html'
    context_object_name = 'lesson'
    slug_field = 'slug'
    slug_url_kwarg = 'lesson_slug'

    def get_queryset(self):
        """Filter by category"""
        category_code = self.kwargs.get('category_code')
        return SituationLesson.objects.filter(
            category__code=category_code
        ).select_related('category')

    def get_context_data(self, **kwargs):
        """Add expressions"""
        context = super().get_context_data(**kwargs)

        # Get all expressions for this lesson
        context['expressions'] = SituationExpression.objects.filter(
            lesson=self.object
        ).order_by('order')

        context['selected_language'] = self.request.GET.get('language', 'EN')

        return context

    def get(self, request, *args, **kwargs):
        """Increment view count"""
        self.object = self.get_object()
        self.object.view_count += 1
        self.object.save(update_fields=['view_count'])
        context = self.get_context_data(object=self.object)
        return self.render_to_response(context)
