#!/usr/bin/env python3
"""
Script to add legal document management views to accounts/views.py
Automatically appends view code and necessary imports to the file.
"""

import os

# Path to the views.py file
VIEWS_FILE = '/Users/kyungjunkang/PycharmProjects/hypehere/accounts/views.py'

# Imports to add at the top of the file
IMPORTS_TO_ADD = """
# Legal Document Management imports
from .models import LegalDocument, LegalDocumentVersion
from .decorators import prime_or_superuser_required
from django.http import JsonResponse
from django.utils.translation import get_language
import json
"""

# View code to append at the end of the file
VIEWS_CODE = """

# ========== Legal Document Management Views ==========

class LegalDocumentListView(TemplateView):
    \"\"\"List all legal documents (Prime/Superuser only)\"\"\"
    template_name = 'accounts/admin/legal_document_list.html'

    @method_decorator(prime_or_superuser_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Group documents by type and language
        documents = {}
        for doc_type, doc_name in LegalDocument.DOCUMENT_TYPES:
            documents[doc_type] = {}
            for lang_code, lang_name in LegalDocument.LANGUAGE_CHOICES:
                doc = LegalDocument.objects.filter(
                    document_type=doc_type,
                    language=lang_code,
                    is_active=True
                ).first()
                documents[doc_type][lang_code] = doc

        context['documents'] = documents
        context['document_types'] = LegalDocument.DOCUMENT_TYPES
        context['languages'] = LegalDocument.LANGUAGE_CHOICES
        return context


class LegalDocumentEditView(TemplateView):
    \"\"\"Edit a legal document (Prime/Superuser only)\"\"\"
    template_name = 'accounts/admin/legal_document_edit.html'

    @method_decorator(prime_or_superuser_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        doc_type = kwargs.get('document_type')
        language = kwargs.get('language')

        # Get or create document
        document, created = LegalDocument.objects.get_or_create(
            document_type=doc_type,
            language=language,
            is_active=True,
            defaults={
                'title': dict(LegalDocument.DOCUMENT_TYPES).get(doc_type, ''),
                'content': '',
                'version': '1.0',
                'effective_date': timezone.now().date(),
                'created_by': self.request.user
            }
        )

        context['document'] = document
        context['document_type_display'] = dict(LegalDocument.DOCUMENT_TYPES).get(doc_type)
        context['language_display'] = dict(LegalDocument.LANGUAGE_CHOICES).get(language)
        return context


class LegalDocumentSaveView(View):
    \"\"\"Save legal document changes (POST only, Prime/Superuser only)\"\"\"

    @method_decorator(prime_or_superuser_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def post(self, request, document_type, language):
        try:
            data = json.loads(request.body)

            # Get or create document
            document, created = LegalDocument.objects.get_or_create(
                document_type=document_type,
                language=language,
                is_active=True,
                defaults={
                    'created_by': request.user
                }
            )

            # Update fields
            document.title = data.get('title', document.title)
            document.content = data.get('content', '')
            document.version = data.get('version', document.version)
            document.effective_date = data.get('effective_date', document.effective_date)
            document.modified_by = request.user

            # Save (automatically creates version history via model's save method)
            document.save()

            return JsonResponse({
                'success': True,
                'message': '문서가 성공적으로 저장되었습니다.',
                'version': document.version,
                'updated_at': document.updated_at.isoformat()
            })

        except Exception as e:
            return JsonResponse({
                'success': False,
                'message': f'저장 중 오류가 발생했습니다: {str(e)}'
            }, status=400)


class LegalDocumentVersionListView(TemplateView):
    \"\"\"View version history of a legal document (Prime/Superuser only)\"\"\"
    template_name = 'accounts/admin/legal_document_versions.html'

    @method_decorator(prime_or_superuser_required)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        doc_type = kwargs.get('document_type')
        language = kwargs.get('language')

        document = LegalDocument.objects.filter(
            document_type=doc_type,
            language=language,
            is_active=True
        ).first()

        if document:
            context['document'] = document
            context['versions'] = document.versions.all()

        return context
"""

# Code to replace existing legal views
MODIFIED_VIEWS_CODE = """

# ========== Modified Legal Document Views (load from DB first, fallback to templates) ==========

class TermsOfServiceView(TemplateView):
    template_name = 'accounts/legal/terms_of_service.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        lang = get_language()
        document = LegalDocument.objects.filter(
            document_type='terms',
            language=lang,
            is_active=True
        ).first()
        if document:
            context['document'] = document
            context['use_database'] = True
        else:
            context['use_database'] = False
        return context


class PrivacyPolicyView(TemplateView):
    template_name = 'accounts/legal/privacy_policy.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        lang = get_language()
        document = LegalDocument.objects.filter(
            document_type='privacy',
            language=lang,
            is_active=True
        ).first()
        if document:
            context['document'] = document
            context['use_database'] = True
        else:
            context['use_database'] = False
        return context


class CookiePolicyView(TemplateView):
    template_name = 'accounts/legal/cookie_policy.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        lang = get_language()
        document = LegalDocument.objects.filter(
            document_type='cookies',
            language=lang,
            is_active=True
        ).first()
        if document:
            context['document'] = document
            context['use_database'] = True
        else:
            context['use_database'] = False
        return context


class CommunityGuidelinesView(TemplateView):
    template_name = 'accounts/legal/community_guidelines.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        lang = get_language()
        document = LegalDocument.objects.filter(
            document_type='community',
            language=lang,
            is_active=True
        ).first()
        if document:
            context['document'] = document
            context['use_database'] = True
        else:
            context['use_database'] = False
        return context
"""


def add_imports():
    """Add necessary imports to the top of views.py"""
    with open(VIEWS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if imports already exist
    if 'from .models import LegalDocument' in content:
        print("✅ Imports already exist, skipping...")
        return

    # Find the last import line and add our imports after it
    lines = content.split('\n')
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('from ') or line.startswith('import '):
            last_import_idx = i

    # Insert imports after the last import
    lines.insert(last_import_idx + 1, IMPORTS_TO_ADD.strip())

    # Write back
    with open(VIEWS_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print("✅ Imports added successfully")


def replace_existing_views():
    """Replace existing legal views with database-enabled versions"""
    with open(VIEWS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if already modified
    if 'use_database' in content:
        print("✅ Existing views already modified, skipping...")
        return

    # Find and replace each view
    views_to_replace = [
        ('TermsOfServiceView', 'class TermsOfServiceView(TemplateView):\n    template_name = \'accounts/legal/terms_of_service.html\''),
        ('PrivacyPolicyView', 'class PrivacyPolicyView(TemplateView):\n    template_name = \'accounts/legal/privacy_policy.html\''),
        ('CookiePolicyView', 'class CookiePolicyView(TemplateView):\n    template_name = \'accounts/legal/cookie_policy.html\''),
        ('CommunityGuidelinesView', 'class CommunityGuidelinesView(TemplateView):\n    template_name = \'accounts/legal/community_guidelines.html\''),
    ]

    # For simplicity, we'll add a comment above existing views
    # The new versions will be added separately
    print("⚠️  Note: Existing views will remain, new DB-enabled versions added separately")
    print("    You may want to manually remove old versions after verifying the new ones work")


def add_new_views():
    """Append new legal document management views to the end of the file"""
    with open(VIEWS_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if views already exist
    if 'LegalDocumentListView' in content:
        print("✅ New views already exist, skipping...")
        return

    # Append new views
    with open(VIEWS_FILE, 'a', encoding='utf-8') as f:
        f.write(VIEWS_CODE)
        f.write(MODIFIED_VIEWS_CODE)

    print("✅ New views added successfully")


def main():
    print("=== Adding Legal Document Management Views ===\n")

    # Step 1: Add imports
    print("Step 1: Adding imports...")
    add_imports()

    # Step 2: Replace existing views (informational only)
    print("\nStep 2: Checking existing views...")
    replace_existing_views()

    # Step 3: Add new views
    print("\nStep 3: Adding new views...")
    add_new_views()

    print("\n✅ All done!")
    print("\nNext steps:")
    print("1. Review the changes in accounts/views.py")
    print("2. Add URL routes to accounts/urls.py")
    print("3. Create the template files")


if __name__ == "__main__":
    main()
