"""
Django Management Command: migrate_legal_docs
템플릿에 하드코딩된 법적 문서를 데이터베이스로 마이그레이션
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from accounts.models import LegalDocument
from django.utils import timezone
from datetime import date
import re
import os

User = get_user_model()


class Command(BaseCommand):
    help = '템플릿에 하드코딩된 법적 문서를 데이터베이스로 마이그레이션합니다'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('\n=== 법적 문서 마이그레이션 시작 ===\n'))

        # 슈퍼유저 가져오기 (첫 번째 슈퍼유저 사용)
        superuser = User.objects.filter(is_superuser=True).first()
        if not superuser:
            self.stdout.write(self.style.ERROR('슈퍼유저를 찾을 수 없습니다. 슈퍼유저를 먼저 생성하세요.'))
            return

        # 문서 타입과 템플릿 파일 매핑
        documents = {
            'terms': {
                'file': 'accounts/templates/accounts/legal/terms_of_service.html',
                'title': 'HypeHere 이용약관'
            },
            'privacy': {
                'file': 'accounts/templates/accounts/legal/privacy_policy.html',
                'title': 'HypeHere 개인정보처리방침'
            },
            'cookies': {
                'file': 'accounts/templates/accounts/legal/cookie_policy.html',
                'title': 'HypeHere 쿠키 정책'
            },
            'community': {
                'file': 'accounts/templates/accounts/legal/community_guidelines.html',
                'title': 'HypeHere 커뮤니티 가이드라인'
            },
        }

        success_count = 0
        error_count = 0

        for doc_type, doc_info in documents.items():
            try:
                self.stdout.write(f'\n처리 중: {doc_info["title"]} ({doc_type})')

                # 이미 DB에 있는지 확인
                existing = LegalDocument.objects.filter(
                    document_type=doc_type,
                    language='ko',
                    is_active=True
                ).exists()

                if existing:
                    self.stdout.write(self.style.WARNING(f'  - 이미 존재하는 문서입니다. 건너뜁니다.'))
                    continue

                # 템플릿 파일 읽기
                file_path = os.path.join(
                    os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))),
                    doc_info['file']
                )

                if not os.path.exists(file_path):
                    self.stdout.write(self.style.ERROR(f'  - 템플릿 파일을 찾을 수 없습니다: {file_path}'))
                    error_count += 1
                    continue

                with open(file_path, 'r', encoding='utf-8') as f:
                    template_content = f.read()

                # {% else %} 블록에서 하드코딩된 콘텐츠 추출
                content = self._extract_fallback_content(template_content)

                if not content:
                    self.stdout.write(self.style.ERROR(f'  - 템플릿에서 콘텐츠를 추출할 수 없습니다.'))
                    error_count += 1
                    continue

                # 데이터베이스에 저장
                legal_doc = LegalDocument.objects.create(
                    document_type=doc_type,
                    language='ko',
                    title=doc_info['title'],
                    content=content,
                    version='1.0',
                    is_active=True,
                    effective_date=date.today(),
                    created_by=superuser,
                    modified_by=superuser
                )

                self.stdout.write(self.style.SUCCESS(f'  ✓ 성공: 버전 {legal_doc.version} 생성'))
                self.stdout.write(f'    - 시행일: {legal_doc.effective_date}')
                self.stdout.write(f'    - 콘텐츠 크기: {len(content):,}자')
                success_count += 1

            except Exception as e:
                self.stdout.write(self.style.ERROR(f'  - 오류: {str(e)}'))
                error_count += 1

        # 최종 결과
        self.stdout.write(self.style.SUCCESS(f'\n=== 마이그레이션 완료 ==='))
        self.stdout.write(f'성공: {success_count}개')
        self.stdout.write(f'실패: {error_count}개')
        self.stdout.write(f'총 문서: {LegalDocument.objects.filter(language="ko", is_active=True).count()}개\n')

    def _extract_fallback_content(self, template_content):
        """
        템플릿에서 {% else %} 블록의 하드코딩된 콘텐츠 추출
        """
        # {% if use_database %} ... {% else %} ... {% endif %} 패턴에서 else 블록 추출
        pattern = r'{%\s*else\s*%}(.*?){%\s*endif\s*%}'
        match = re.search(pattern, template_content, re.DOTALL)

        if match:
            content = match.group(1).strip()

            # 불필요한 태그 및 공백 정리
            content = re.sub(r'^\s*<div[^>]*>\s*', '', content, flags=re.DOTALL)  # 시작 div 제거
            content = re.sub(r'\s*</div>\s*$', '', content, flags=re.DOTALL)  # 끝 div 제거

            return content.strip()

        return None
