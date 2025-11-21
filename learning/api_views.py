from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import SituationExpression
from .serializers import BookmarkedExpressionSerializer, SituationExpressionSerializer


class BookmarkedExpressionsView(APIView):
    """
    Get bookmarked expressions by IDs
    POST: Fetch expression details for bookmarked expression IDs
    """
    def post(self, request):
        """Fetch expressions by IDs from request body"""
        expression_ids = request.data.get('expression_ids', [])

        if not expression_ids:
            return Response({'expressions': []}, status=status.HTTP_200_OK)

        # Validate expression_ids are integers
        try:
            expression_ids = [int(id) for id in expression_ids]
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid expression IDs format'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Fetch expressions with related lesson and category data
        expressions = SituationExpression.objects.filter(
            id__in=expression_ids
        ).select_related('lesson__category').order_by('lesson__category__order', 'lesson__order', 'order')

        serializer = BookmarkedExpressionSerializer(expressions, many=True)
        return Response({'expressions': serializer.data}, status=status.HTTP_200_OK)


class SituationExpressionCreateView(APIView):
    """
    Create new situation expression (staff only)
    POST: Create expression with auto-incrementing order
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Create new expression"""
        if not request.user.is_staff:
            return Response(
                {'error': 'Only staff members can create expressions.'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Auto-calculate order if not provided
        lesson_id = request.data.get('lesson')
        if lesson_id and 'order' not in request.data:
            last_expression = SituationExpression.objects.filter(
                lesson_id=lesson_id
            ).order_by('-order').first()

            if last_expression:
                request.data['order'] = last_expression.order + 1
            else:
                request.data['order'] = 0

        serializer = SituationExpressionSerializer(
            data=request.data,
            context={'request': request}
        )

        if serializer.is_valid():
            expression = serializer.save()
            return Response(
                SituationExpressionSerializer(expression).data,
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SituationExpressionUpdateView(APIView):
    """
    Update existing situation expression (staff only)
    PUT: Update expression fields
    """
    permission_classes = [IsAuthenticated]

    def put(self, request, expression_id):
        """Update expression"""
        if not request.user.is_staff:
            return Response(
                {'error': 'Only staff members can update expressions.'},
                status=status.HTTP_403_FORBIDDEN
            )

        expression = get_object_or_404(SituationExpression, id=expression_id)

        serializer = SituationExpressionSerializer(
            expression,
            data=request.data,
            partial=True,
            context={'request': request}
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SituationExpressionDeleteView(APIView):
    """
    Delete situation expression (staff only)
    DELETE: Remove expression and reorder remaining expressions
    """
    permission_classes = [IsAuthenticated]

    def delete(self, request, expression_id):
        """Delete expression"""
        if not request.user.is_staff:
            return Response(
                {'error': 'Only staff members can delete expressions.'},
                status=status.HTTP_403_FORBIDDEN
            )

        expression = get_object_or_404(SituationExpression, id=expression_id)
        lesson_id = expression.lesson_id
        deleted_order = expression.order

        expression.delete()

        # Reorder remaining expressions in the lesson
        remaining_expressions = SituationExpression.objects.filter(
            lesson_id=lesson_id,
            order__gt=deleted_order
        ).order_by('order')

        for expr in remaining_expressions:
            expr.order -= 1
            expr.save(update_fields=['order'])

        return Response(
            {'message': 'Expression deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )
