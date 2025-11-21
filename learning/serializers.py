from rest_framework import serializers
from .models import SituationExpression


class BookmarkedExpressionSerializer(serializers.ModelSerializer):
    """Serializer for bookmarked situation expressions"""
    lesson_title = serializers.CharField(source='lesson.title_ko', read_only=True)
    lesson_slug = serializers.CharField(source='lesson.slug', read_only=True)
    category_name = serializers.CharField(source='lesson.category.name_ko', read_only=True)
    category_code = serializers.CharField(source='lesson.category.code', read_only=True)
    category_icon = serializers.CharField(source='lesson.category.icon', read_only=True)

    class Meta:
        model = SituationExpression
        fields = [
            'id', 'expression', 'translation', 'pronunciation',
            'situation_context', 'vocabulary', 'lesson_title',
            'lesson_slug', 'category_name', 'category_code', 'category_icon'
        ]
        read_only_fields = ['id']


class SituationExpressionSerializer(serializers.ModelSerializer):
    """Serializer for creating/updating situation expressions (admin only)"""

    class Meta:
        model = SituationExpression
        fields = [
            'id', 'lesson', 'expression', 'translation', 'pronunciation',
            'situation_context', 'vocabulary', 'order', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate(self, data):
        """Validate that user is staff"""
        request = self.context.get('request')
        if not request or not request.user.is_staff:
            raise serializers.ValidationError("Only staff members can create/edit expressions.")
        return data

    def validate_vocabulary(self, value):
        """Ensure vocabulary is a list of strings"""
        if not isinstance(value, list):
            raise serializers.ValidationError("Vocabulary must be a list.")
        for item in value:
            if not isinstance(item, str):
                raise serializers.ValidationError("Each vocabulary item must be a string.")
        return value
