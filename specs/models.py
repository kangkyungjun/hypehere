from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class Specification(models.Model):
    """
    Development notes and requirements management
    For tracking HypeHere project specifications
    """
    CATEGORY_CHOICES = [
        ('feature', '기능'),
        ('design', '디자인'),
        ('architecture', '아키텍처'),
        ('api', 'API'),
        ('database', '데이터베이스'),
        ('testing', '테스팅'),
        ('deployment', '배포'),
        ('documentation', '문서'),
        ('bug', '버그'),
        ('enhancement', '개선사항'),
    ]

    STATUS_CHOICES = [
        ('draft', '초안'),
        ('review', '검토중'),
        ('approved', '승인됨'),
        ('implemented', '구현됨'),
        ('deprecated', '폐기됨'),
    ]

    title = models.CharField(max_length=200, verbose_name='제목')
    category = models.CharField(
        max_length=50,
        choices=CATEGORY_CHOICES,
        default='feature',
        verbose_name='카테고리'
    )
    content = models.TextField(verbose_name='내용')
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='draft',
        verbose_name='상태'
    )
    version = models.CharField(max_length=20, default='v1.0', verbose_name='버전')
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='specifications',
        verbose_name='작성자'
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='생성일')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='수정일')

    class Meta:
        ordering = ['-created_at']
        verbose_name = '개발 노트'
        verbose_name_plural = '개발 노트'

    def __str__(self):
        return f"[{self.get_category_display()}] {self.title}"
