from django import forms
from accounts.models import LegalDocument


class LegalDocumentForm(forms.ModelForm):
    """법적 문서 편집 폼"""

    class Meta:
        model = LegalDocument
        fields = ['title', 'content', 'effective_date', 'version']
        widgets = {
            'content': forms.Textarea(attrs={
                'rows': 20,
                'class': 'legal-content-editor',
                'placeholder': '문서 내용을 입력하세요...'
            }),
            'title': forms.TextInput(attrs={
                'class': 'legal-title-input',
                'placeholder': '문서 제목'
            }),
            'effective_date': forms.DateInput(attrs={
                'type': 'date',
                'class': 'legal-date-input'
            }),
            'version': forms.TextInput(attrs={
                'class': 'legal-version-input',
                'placeholder': '예: 1.0'
            }),
        }
        labels = {
            'title': '제목',
            'content': '내용',
            'effective_date': '시행일',
            'version': '버전',
        }
        help_texts = {
            'content': 'HTML 태그를 사용할 수 있습니다.',
            'version': '문서 버전을 입력하세요 (예: 1.0, 1.1)',
        }
