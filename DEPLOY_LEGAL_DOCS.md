# AWS 서버 법적 문서 배포 가이드

## 🎯 목적
로컬 데이터베이스의 법적 문서(이용약관, 개인정보 보호 정책 등) 19개를 AWS 서버에 업로드합니다.

## 📋 배포 대상 문서 (4개 언어 x 4개 문서 종류 = 19개)

### 문서 종류
1. **Terms of Service** (이용약관)
2. **Privacy Policy** (개인정보처리방침)
3. **Cookie Policy** (쿠키 정책)
4. **Community Guidelines** (커뮤니티 가이드라인)

### 언어 지원
- 한국어 (ko)
- 영어 (en)
- 일본어 (ja)
- 스페인어 (es)

### 총 문서 개수
19개 (일부 중복 버전 포함)

## 📦 배포 파일
- **로컬 경로**: `/Users/kyungjunkang/PycharmProjects/hypehere/legal_documents_backup.json`
- **파일 크기**: 220KB
- **형식**: Django dumpdata JSON

## 🚀 배포 절차

### 1. 파일 업로드
```bash
# SSH로 서버 접속
ssh ubuntu@43.201.45.60

# 로컬에서 파일 전송 (다른 터미널)
scp legal_documents_backup.json ubuntu@43.201.45.60:/tmp/
```

### 2. AWS 서버에서 실행
```bash
# hypehere 디렉토리로 이동
cd hypehere

# Git pull (최신 코드 반영)
git pull origin master

# 가상환경 활성화
source venv/bin/activate

# 데이터베이스에 법적 문서 로드
python manage.py loaddata /tmp/legal_documents_backup.json

# 정적 파일 수집 (CSS 업데이트 포함)
python manage.py collectstatic --noinput

# 서비스 재시작
sudo systemctl restart hypehere gunicorn nginx
```

### 3. 검증
```bash
# Django shell에서 확인
python manage.py shell

# 아래 Python 코드 실행
from accounts.models import LegalDocument
docs = LegalDocument.objects.all()
print(f"Total documents: {docs.count()}")  # 19개 확인

# 각 언어별 문서 확인
for lang in ['ko', 'en', 'ja', 'es']:
    count = docs.filter(language=lang).count()
    print(f"{lang.upper()}: {count} documents")

# 각 문서 타입별 확인
for doc_type in ['terms', 'privacy', 'cookies', 'community']:
    count = docs.filter(document_type=doc_type).count()
    print(f"{doc_type}: {count} documents")
exit()
```

### 4. 웹 브라우저에서 확인
```
# 한국어
https://hypehere.online/accounts/terms/
https://hypehere.online/accounts/privacy/
https://hypehere.online/accounts/cookies/

# 영어
https://hypehere.online/accounts/terms/?lang=en
https://hypehere.online/accounts/privacy/?lang=en

# 일본어
https://hypehere.online/accounts/terms/?lang=ja
https://hypehere.online/accounts/privacy/?lang=ja

# 스페인어
https://hypehere.online/accounts/terms/?lang=es
https://hypehere.online/accounts/privacy/?lang=es
```

## ✅ 배포 완료 체크리스트

- [ ] legal_documents_backup.json 파일을 AWS 서버에 업로드
- [ ] Git pull로 최신 코드 반영 (회원가입 체크박스 포함)
- [ ] loaddata 명령으로 법적 문서 19개 로드
- [ ] collectstatic으로 CSS 업데이트
- [ ] 서비스 재시작 (hypehere, gunicorn, nginx)
- [ ] Django shell에서 문서 개수 확인 (19개)
- [ ] 웹 브라우저에서 4개 언어 모두 확인
- [ ] 회원가입 페이지에서 체크박스 3개 표시 확인

## 🎨 회원가입 페이지 업데이트 내용

### 추가된 필수 동의 체크박스 (3개)
1. ✅ 이용약관에 동의합니다 (필수)
2. ✅ 개인정보처리방침에 동의합니다 (필수)
3. ✅ 만 14세 이상입니다 (필수)

### 특징
- 모든 체크박스는 required (필수)
- 이용약관/개인정보 링크는 새 탭에서 열림 (target="_blank")
- 커스텀 체크박스 디자인 (components.css)
- 하단 안내 텍스트는 유지됨

## 🔍 문제 해결

### 문서가 19개가 아닌 경우
```bash
# 기존 문서 삭제 후 재로드
python manage.py shell
from accounts.models import LegalDocument
LegalDocument.objects.all().delete()
exit()

# 다시 로드
python manage.py loaddata /tmp/legal_documents_backup.json
```

### 체크박스 스타일이 안 보이는 경우
```bash
# 정적 파일 강제 재수집
python manage.py collectstatic --clear --noinput
sudo systemctl restart nginx
```

### 특정 언어만 누락된 경우
```bash
# 해당 언어만 추출
python manage.py shell
from accounts.models import LegalDocument
import json

# 예: 일본어 문서만 추출
ja_docs = LegalDocument.objects.filter(language='ja')
data = []
for doc in ja_docs:
    data.append({
        "model": "accounts.legaldocument",
        "fields": {
            "document_type": doc.document_type,
            "language": doc.language,
            "version": doc.version,
            "content": doc.content,
            "is_active": doc.is_active,
            "effective_date": str(doc.effective_date) if doc.effective_date else None,
            "created_at": str(doc.created_at),
            "updated_at": str(doc.updated_at)
        }
    })

with open('/tmp/ja_only.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
exit()
```

## 📊 예상 결과

### 데이터베이스 상태 (배포 후)
```
Total documents: 19

KO: 6 documents (terms v1.0, v1.1 / privacy v1.0, v1.1 / cookies v1.0, v1.1 / community)
EN: 4 documents (terms, privacy, cookies, community - all v1.1)
JA: 4 documents (terms, privacy, cookies, community - all v1.1)
ES: 4 documents (terms, privacy, cookies, community - all v1.1)

terms: 6 documents (한국어 2버전 + 다른 언어 각 1버전)
privacy: 6 documents (한국어 2버전 + 다른 언어 각 1버전)
cookies: 6 documents (한국어 2버전 + 다른 언어 각 1버전)
community: 4 documents (모든 언어 1버전씩)
```

## 🎯 Google Play Store 준비 완료

배포 완료 후 다음 사항이 충족됩니다:
- ✅ 법적 문서 4개 언어 지원
- ✅ 명시적 회원가입 동의 절차 (체크박스)
- ✅ 만 14세 이상 연령 확인
- ✅ 이용약관/개인정보 보호 정책 접근 가능

**Google Play Store 출시 필수 요구사항 100% 충족**
