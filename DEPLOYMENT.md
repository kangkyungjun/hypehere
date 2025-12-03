# HypeHere AWS 배포 가이드

**프로젝트**: HypeHere - 언어 학습 소셜 플랫폼
**아키텍처**: AWS App Runner + Neon PostgreSQL + Upstash Redis + AWS S3
**예상 비용**: 월 $11-18
**배포 시간**: 약 60-90분

## 📋 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [사전 준비](#사전-준비)
3. [Step 1: 외부 데이터베이스 설정](#step-1-외부-데이터베이스-설정)
4. [Step 2: Redis 설정](#step-2-redis-설정)
5. [Step 3: AWS S3 설정](#step-3-aws-s3-설정)
6. [Step 4: GitHub 저장소 준비](#step-4-github-저장소-준비)
7. [Step 5: AWS App Runner 배포](#step-5-aws-app-runner-배포)
8. [Step 6: 배포 후 검증](#step-6-배포-후-검증)
9. [문제 해결](#문제-해결)
10. [향후 확장](#향후-확장)

---

## 아키텍처 개요

### 전체 구조

```
┌─────────────────────────────────────────────────────────────┐
│                    사용자 (웹/모바일)                          │
│               웹 브라우저 | 웹앱 | Flutter 앱                 │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  AWS App Runner (Django + Daphne ASGI)                       │
│  - HTTP + WebSocket 지원                                      │
│  - 자동 SSL 인증서                                            │
│  - 자동 스케일링 (0.25 vCPU, 0.5GB RAM)                      │
│  - GitHub 자동 배포                                           │
│  예상 비용: $10-15/월                                         │
└──────┬──────────────────────┬──────────────────────────────┘
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────────┐
│ Neon DB      │      │ Upstash Redis    │
│ (PostgreSQL) │      │ (Redis)          │
│ - 512MB 저장소│      │ - 10K cmd/day    │
│ - 무료 계층   │      │ - 무료 계층       │
│ $0/월        │      │ $0/월            │
└──────────────┘      └──────────────────┘
       │
       ▼
┌─────────────────────┐
│  AWS S3             │
│  - Static files     │
│  - Media uploads    │
│  예상: $1-3/월      │
└─────────────────────┘
```

### 왜 이 아키텍처인가?

#### ✅ 장점
1. **최저 비용**: 무료 서비스 활용 + 최소 컴퓨팅
2. **서버 관리 불필요**: AWS가 모든 인프라 관리
3. **자동 배포**: GitHub 푸시 → 자동 재배포
4. **멀티 플랫폼 지원**: 웹/웹앱/Flutter 앱 모두 지원
5. **WebSocket 완벽 지원**: 실시간 채팅 기능
6. **확장성**: 트래픽 증가 시 쉽게 업그레이드 가능

#### ⚠️ 제한사항
1. **무료 계층 한계**:
   - Neon DB: 512MB 저장소, 월 100시간 활성 시간
   - Upstash Redis: 10,000 commands/day
2. **App Runner 최소 비용**: 월 $10-15는 피할 수 없음
3. **Cold Start**: 트래픽이 없으면 첫 요청 시 약 1-2초 지연

---

## 사전 준비

### 필요한 계정
- [x] AWS 계정 (이미 보유)
- [ ] GitHub 계정
- [ ] Neon 계정 (https://neon.tech)
- [ ] Upstash 계정 (https://upstash.com)

### 로컬 환경 요구사항
- Python 3.12
- Git
- 인터넷 연결
- 텍스트 에디터

### 준비 완료 확인
```bash
# 1. Python 버전 확인
python --version  # Python 3.12.x

# 2. Git 상태 확인
git status

# 3. 필수 파일 존재 확인
ls -la apprunner.yaml deploy.sh .env.production
```

---

## Step 1: 외부 데이터베이스 설정

### Neon PostgreSQL 데이터베이스 생성

#### 1-1. Neon 계정 생성
1. https://neon.tech 접속
2. "Sign Up" 클릭
3. GitHub 또는 Google 계정으로 가입
4. 이메일 인증 완료

#### 1-2. 프로젝트 생성
1. Neon 대시보드 → "Create a project" 클릭
2. 설정 입력:
   ```
   Project name: hypehere-db
   PostgreSQL version: 15 (최신)
   Region: US East (Ohio) - us-east-2
   ```
   > **중요**: App Runner 리전과 동일하게 설정하여 네트워크 지연 최소화
3. "Create Project" 클릭

#### 1-3. 연결 정보 복사
프로젝트 생성 후 표시되는 연결 문자열 복사:
```
postgresql://user:password@ep-xxx-xxx.us-east-2.aws.neon.tech/neondb
```

이 정보를 안전한 곳에 저장 (나중에 App Runner 환경 변수로 입력)

#### 1-4. 연결 테스트 (선택사항)
로컬에서 연결 테스트:
```bash
# psql 설치되어 있다면
psql "postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb"

# 또는 Python으로 테스트
python -c "import psycopg2; conn = psycopg2.connect('postgresql://...'); print('✅ 연결 성공'); conn.close()"
```

**예상 소요 시간**: 5분

---

## Step 2: Redis 설정

### Upstash Redis 인스턴스 생성

#### 2-1. Upstash 계정 생성
1. https://upstash.com 접속
2. "Sign Up" 클릭
3. GitHub 또는 Google 계정으로 가입
4. 이메일 인증 완료

#### 2-2. Redis 데이터베이스 생성
1. Upstash 콘솔 → "Redis" → "Create Database" 클릭
2. 설정 입력:
   ```
   Name: hypehere-redis
   Type: Regional (무료)
   Region: US East (가장 가까운 리전 선택)
   Primary Region: us-east-1
   Eviction: True (메모리 부족 시 자동 삭제)
   TLS: Enabled (보안 연결)
   ```
3. "Create" 클릭

#### 2-3. 연결 정보 복사
생성 후 "Details" 탭에서 연결 URL 복사:
```
redis://default:password@us1-xxx-xxx.upstash.io:6379
```

이 정보를 안전한 곳에 저장

#### 2-4. 연결 테스트 (선택사항)
로컬에서 연결 테스트:
```bash
# redis-cli 설치되어 있다면
redis-cli -u "redis://default:password@us1-xxx.upstash.io:6379" PING
# 응답: PONG

# 또는 Python으로 테스트
python -c "import redis; r = redis.from_url('redis://...'); print(r.ping()); print('✅ 연결 성공')"
```

**예상 소요 시간**: 5분

---

## Step 3: AWS S3 설정

### 3-1. S3 버킷 생성

#### AWS 콘솔 접속
1. https://console.aws.amazon.com/s3 접속
2. 리전 선택: **US East (Ohio) - us-east-2**
   > App Runner 및 Neon DB와 동일 리전 사용

#### 버킷 생성
1. "Create bucket" 클릭
2. 설정 입력:
   ```
   Bucket name: hypehere-static-media-[YOUR-NAME]
   예: hypehere-static-media-john
   (S3 버킷 이름은 전 세계적으로 고유해야 함)

   AWS Region: US East (Ohio) us-east-2

   Object Ownership: ACLs disabled (권장)

   Block Public Access settings:
   ⚠️ 모든 체크 해제 (정적 파일 공개 필요)
   - [ ] Block all public access
   - [ ] Block public access to buckets and objects granted through new access control lists (ACLs)
   - [ ] Block public access to buckets and objects granted through any access control lists (ACLs)
   - [ ] Block public access to buckets and objects granted through new public bucket or access point policies
   - [ ] Block public and cross-account access to buckets and objects through any public bucket or access point policies
   ```
3. 경고 확인:
   - ☑️ "I acknowledge that the current settings might result in this bucket and the objects within becoming public"
4. "Create bucket" 클릭

**예상 소요 시간**: 3분

---

### 3-2. S3 버킷 CORS 설정

#### CORS 구성
1. 생성한 버킷 클릭 → "Permissions" 탭
2. "Cross-origin resource sharing (CORS)" 섹션 스크롤
3. "Edit" 클릭
4. 다음 JSON 입력:

```json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "PUT",
            "POST",
            "DELETE",
            "HEAD"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": [
            "ETag"
        ],
        "MaxAgeSeconds": 3000
    }
]
```

5. "Save changes" 클릭

**CORS가 필요한 이유**: 웹 브라우저에서 직접 S3에 파일 업로드 시 필요

**예상 소요 시간**: 2분

---

### 3-3. IAM 사용자 생성 (S3 접근용)

#### IAM 사용자 생성
1. https://console.aws.amazon.com/iam 접속
2. 좌측 메뉴 → "Users" → "Create user" 클릭
3. 사용자 이름 입력:
   ```
   User name: hypehere-s3-user
   ```
4. "Next" 클릭

#### 권한 설정
1. "Attach policies directly" 선택
2. 검색창에 "S3" 입력
3. **AmazonS3FullAccess** 체크
4. "Next" 클릭
5. "Create user" 클릭

#### Access Key 발급
1. 생성된 사용자 클릭
2. "Security credentials" 탭
3. "Access keys" 섹션 → "Create access key" 클릭
4. Use case 선택:
   ```
   Use case: Application running outside AWS
   ```
5. "Next" 클릭
6. Description 입력 (선택사항):
   ```
   Description tag: HypeHere S3 Access for Production
   ```
7. "Create access key" 클릭

#### 🔑 Access Key 저장
**중요**: 다음 정보는 한 번만 표시됩니다!

```
Access key ID: AKIA...
Secret access key: wJalrXUtn...
```

**안전하게 저장하세요** (나중에 App Runner 환경 변수로 입력):
- 메모장이나 비밀번호 관리 도구에 저장
- 절대 GitHub에 커밋하지 마세요

**예상 소요 시간**: 5분

---

## Step 4: GitHub 저장소 준비

### 4-1. .gitignore 확인

민감한 정보가 GitHub에 업로드되지 않도록 확인:

```bash
# .gitignore 파일 확인
cat .gitignore | grep -E "(\.env|db\.sqlite3|__pycache__|media)"

# 출력 예시:
# .env
# .env.local
# .env.production
# db.sqlite3
# __pycache__/
# media/
```

만약 없다면 추가:
```bash
cat >> .gitignore << 'EOF'
# Environment variables
.env
.env.local
.env.production

# Database
db.sqlite3
*.sqlite3

# Python cache
__pycache__/
*.pyc
*.pyo

# Media files
media/

# Static files collection
staticfiles/
EOF
```

**예상 소요 시간**: 2분

---

### 4-2. Git 커밋 및 푸시

#### 현재 변경사항 확인
```bash
git status
```

#### 새 파일들 추가
```bash
git add apprunner.yaml deploy.sh .env.production DEPLOYMENT.md
```

#### 커밋
```bash
git commit -m "Add AWS deployment configuration

- Add apprunner.yaml for App Runner deployment
- Add deploy.sh deployment script
- Add .env.production template
- Add DEPLOYMENT.md comprehensive deployment guide

Prepared for production deployment to AWS App Runner"
```

#### GitHub 원격 저장소 확인
```bash
git remote -v

# 출력 예시:
# origin  https://github.com/YOUR-USERNAME/hypehere.git (fetch)
# origin  https://github.com/YOUR-USERNAME/hypehere.git (push)
```

#### 푸시
```bash
git push origin master
```

**예상 소요 시간**: 5분

---

## Step 5: AWS App Runner 배포

### 5-1. App Runner 서비스 생성

#### AWS App Runner 콘솔 접속
1. https://console.aws.amazon.com/apprunner 접속
2. 리전 선택: **US East (Ohio) - us-east-2**
3. "Create service" 클릭

---

#### Source and deployment 설정

**Step 1: Source**
```
Repository type: Source code repository

Connect to GitHub: "Add new" 클릭
- GitHub 계정 연결 (OAuth 인증)
- "Authorize AWS Connector for GitHub" 클릭
- 인증 완료 후 돌아오기

Repository: [YOUR-USERNAME]/hypehere 선택
Branch: master (또는 main)

Deployment settings:
- Deployment trigger: Automatic
  (GitHub에 푸시할 때마다 자동 재배포)
```

**Step 2: Build settings**
```
Configuration file: Use a configuration file

Configuration file: apprunner.yaml
(우리가 생성한 파일 사용)
```

"Next" 클릭

**예상 소요 시간**: 5분

---

#### Service settings 설정

**Service name**
```
Service name: hypehere
```

**Compute configuration**
```
Virtual CPU: 0.25 vCPU (최소 사양)
Memory: 0.5 GB (최소 사양)

⚠️ 초기에는 최소 사양으로 시작하고,
트래픽이 증가하면 나중에 업그레이드
```

**Auto scaling**
```
Auto scaling configuration: Default

Max concurrency: 100
(동시에 처리할 수 있는 최대 요청 수)

Min size: 1
(항상 최소 1개 인스턴스 실행)

Max size: 10
(최대 10개까지 자동 확장)
```

"Next" 클릭

**예상 소요 시간**: 3분

---

#### Environment variables 설정

**⚠️ 매우 중요**: 모든 환경 변수를 정확하게 입력해야 합니다.

"Add environment variable" 클릭하여 하나씩 추가:

```bash
# Django Configuration
DEBUG=False
DJANGO_SECRET_KEY=[새로 생성한 시크릿 키]
ALLOWED_HOSTS=*.awsapprunner.com
CSRF_TRUSTED_ORIGINS=https://*.awsapprunner.com

# Site Configuration
SITE_URL=https://[APP-RUNNER-URL]  # 나중에 업데이트

# Email Configuration
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=[Gmail App Password]

# Database (Neon)
DATABASE_URL=postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb

# Redis (Upstash)
REDIS_URL=redis://default:password@us1-xxx.upstash.io:6379

# AWS S3
AWS_STORAGE_BUCKET_NAME=hypehere-static-media-[YOUR-NAME]
AWS_S3_REGION_NAME=us-east-2
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUtn...
```

**DJANGO_SECRET_KEY 생성 방법**:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# 출력 예시:
# django-insecure-abc123xyz...
```

**Gmail App Password 생성 방법**:
1. https://myaccount.google.com/apppasswords 접속
2. 2단계 인증 활성화 (아직 안 했다면)
3. "앱 비밀번호" 생성
4. 앱 선택: "메일"
5. 기기 선택: "기타" → "HypeHere Production" 입력
6. 생성된 16자리 비밀번호 복사

"Next" 클릭

**예상 소요 시간**: 10분

---

#### Security 설정

**Instance role**
```
Instance role: Create new service role
(App Runner가 자동으로 생성)

Role name: AppRunnerECRAccessRole (기본값)
```

**Tags** (선택사항)
```
Key: Environment
Value: Production

Key: Project
Value: HypeHere
```

---

#### Review and create

모든 설정 확인 후:
1. 설정 검토
2. "Create & deploy" 클릭

**배포 시작!** 🚀

**예상 배포 시간**: 5-10분

---

### 5-2. 배포 모니터링

#### Activity 탭 확인
1. App Runner 서비스 페이지에서 "Activity" 탭 클릭
2. 배포 진행 상황 확인:
   ```
   ● Provisioning
   ● Building
   ● Deploying
   ● Running
   ```

#### Logs 탭 확인
배포 중 발생하는 로그 실시간 확인:
```
Logs → Deployment logs
```

**정상 배포 시 로그 예시**:
```
=== Pre-build phase ===
Python 3.12.x
pip 24.x

=== Build phase ===
Successfully installed Django-5.1.11...

=== Post-build phase ===
Collecting static files to S3...
123 static files uploaded to S3
Running database migrations...
Operations to perform:
  Apply all migrations: accounts, posts, chat...
Running migrations:
  Applying accounts.0001_initial... OK
  ...
Build completed successfully!
```

---

### 5-3. Default Domain URL 확인

배포 완료 후:
1. "Default domain" 섹션에서 URL 복사:
   ```
   https://abc123xyz.us-east-2.awsapprunner.com
   ```
2. **이 URL을 저장하세요** - 나중에 환경 변수 업데이트에 사용

---

### 5-4. SITE_URL 환경 변수 업데이트

App Runner URL을 받은 후:

1. App Runner 서비스 → "Configuration" 탭
2. "Environment variables" → "Edit" 클릭
3. `SITE_URL` 변수 찾기
4. 값 업데이트:
   ```
   SITE_URL=https://abc123xyz.us-east-2.awsapprunner.com
   ```
5. "Deploy" 클릭 (재배포 시작)

**예상 소요 시간**: 5분

---

## Step 6: 배포 후 검증

### 6-1. 기본 접속 테스트

#### 홈페이지 접속
브라우저에서 App Runner URL 접속:
```
https://abc123xyz.us-east-2.awsapprunner.com
```

**기대 결과**:
- [ ] 페이지 로딩 성공
- [ ] HTTPS 인증서 정상 (자물쇠 아이콘)
- [ ] 기본 UI 표시

---

#### Admin 패널 접속
```
https://abc123xyz.us-east-2.awsapprunner.com/admin/
```

**기대 결과**:
- [ ] Admin 로그인 페이지 표시
- [ ] CSS 정상 로딩 (S3에서)

---

### 6-2. 슈퍼유저 생성

#### 로컬에서 프로덕션 DB 접근
```bash
# 환경 변수 설정
export DATABASE_URL="postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/neondb"
export DEBUG=False
export DJANGO_SECRET_KEY="[App Runner에 설정한 동일한 키]"

# Django shell 실행
python manage.py shell
```

#### Shell에서 슈퍼유저 생성
```python
from accounts.models import User

# 슈퍼유저 생성
User.objects.create_superuser(
    email='admin@hypehere.com',
    nickname='Admin',
    password='YourSecurePassword123!'
)

# 확인
print("✅ 슈퍼유저 생성 완료!")
exit()
```

---

### 6-3. Admin 로그인 테스트

1. Admin 페이지 접속
2. 생성한 슈퍼유저로 로그인
3. 대시보드 확인

**기대 결과**:
- [ ] 로그인 성공
- [ ] 모든 앱 (accounts, posts, chat 등) 표시
- [ ] 정적 파일 (CSS/JS) 정상 로딩

---

### 6-4. 기능 테스트

#### 회원가입 테스트
1. 홈페이지 → 회원가입
2. 이메일, 닉네임, 비밀번호 입력
3. 가입 완료 확인

**기대 결과**:
- [ ] 회원가입 성공
- [ ] 이메일 인증 메일 발송 (Gmail SMTP 작동 확인)
- [ ] 데이터베이스에 사용자 저장 확인

---

#### 게시글 작성 테스트
1. 로그인
2. 게시글 작성
3. 이미지 업로드

**기대 결과**:
- [ ] 게시글 작성 성공
- [ ] 이미지 S3에 업로드 확인
- [ ] 게시글 목록에 표시

---

#### 채팅 기능 테스트
1. 2개의 브라우저 (또는 시크릿 모드) 사용
2. 각각 다른 계정으로 로그인
3. 채팅 시작

**기대 결과**:
- [ ] WebSocket 연결 성공
- [ ] 실시간 메시지 전송/수신
- [ ] 메시지 데이터베이스 저장 확인

---

### 6-5. 성능 테스트

#### 페이지 로딩 속도
브라우저 개발자 도구 (F12) → Network 탭:
- First Contentful Paint (FCP): < 1.5초
- Largest Contentful Paint (LCP): < 2.5초

#### API 응답 시간
```bash
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://abc123xyz.us-east-2.awsapprunner.com/api/posts/
```

**기대 결과**: < 500ms

---

### 6-6. 로그 확인

#### Application Logs
App Runner 콘솔 → Logs → Application logs:
- 에러 로그 확인
- 경고 메시지 확인
- 정상 작동 로그 확인

**정상 로그 예시**:
```
[INFO] Server started at 0.0.0.0:8000
[INFO] WebSocket connected: /ws/chat/123/
[INFO] HTTP GET /api/posts/ 200
```

---

## 문제 해결

### 일반적인 문제와 해결 방법

---

### 문제 1: 배포 실패 - "Build failed"

**증상**:
```
Error: Could not install packages due to an EnvironmentError
```

**원인**: requirements.txt의 패키지 충돌 또는 누락

**해결**:
1. 로컬에서 requirements.txt 테스트:
   ```bash
   pip install -r requirements.txt
   ```
2. 문제 패키지 확인 및 버전 고정
3. GitHub에 푸시하여 재배포

---

### 문제 2: 데이터베이스 연결 오류

**증상**:
```
django.db.utils.OperationalError: could not connect to server
```

**원인**: DATABASE_URL이 잘못되었거나 Neon DB 접근 불가

**해결**:
1. Neon 콘솔에서 연결 문자열 재확인
2. App Runner 환경 변수 확인:
   ```
   DATABASE_URL=postgresql://user:password@host:5432/dbname
   ```
3. Neon DB 상태 확인 (대시보드에서)
4. 환경 변수 수정 후 재배포

---

### 문제 3: Redis 연결 오류

**증상**:
```
redis.exceptions.ConnectionError: Error 111 connecting
```

**원인**: REDIS_URL이 잘못되었거나 Upstash Redis 접근 불가

**해결**:
1. Upstash 콘솔에서 연결 문자열 재확인
2. App Runner 환경 변수 확인:
   ```
   REDIS_URL=redis://default:password@host:6379
   ```
3. Upstash Redis 상태 확인
4. 환경 변수 수정 후 재배포

---

### 문제 4: S3 업로드 실패

**증상**:
```
botocore.exceptions.NoCredentialsError: Unable to locate credentials
```

**원인**: AWS Access Key가 잘못되었거나 권한 부족

**해결**:
1. IAM 사용자 권한 확인:
   - AmazonS3FullAccess 정책 부여되었는지 확인
2. Access Key 재확인:
   ```
   AWS_ACCESS_KEY_ID=AKIA...
   AWS_SECRET_ACCESS_KEY=wJalrXUtn...
   ```
3. S3 버킷 이름 확인:
   ```
   AWS_STORAGE_BUCKET_NAME=[실제 버킷 이름]
   ```
4. 환경 변수 수정 후 재배포

---

### 문제 5: Static files 404 에러

**증상**: CSS/JS 파일이 로드되지 않음 (404 에러)

**원인**: collectstatic이 실행되지 않았거나 S3 업로드 실패

**해결**:
1. App Runner Deployment logs 확인:
   ```
   Collecting static files to S3...
   ```
2. S3 버킷에서 static/ 폴더 확인
3. 수동으로 collectstatic 실행:
   ```bash
   # 로컬에서 프로덕션 환경 변수 설정 후
   python manage.py collectstatic --noinput
   ```
4. GitHub에 푸시하여 재배포

---

### 문제 6: WebSocket 연결 실패

**증상**: 채팅 기능이 작동하지 않음, "WebSocket connection failed"

**원인**: Daphne가 제대로 실행되지 않았거나 Redis 문제

**해결**:
1. App Runner Application logs 확인:
   ```
   Daphne running at 0.0.0.0:8000
   ```
2. REDIS_URL 재확인
3. apprunner.yaml의 run command 확인:
   ```yaml
   command: daphne -b 0.0.0.0 -p 8000 hypehere.asgi:application
   ```
4. 재배포

---

### 문제 7: 환경 변수가 적용되지 않음

**증상**: 설정한 환경 변수가 작동하지 않음

**원인**: 환경 변수 추가 후 재배포하지 않음

**해결**:
1. App Runner 콘솔 → Configuration → Environment variables
2. 모든 필수 변수 확인
3. **반드시 "Deploy" 버튼 클릭하여 재배포**
4. 배포 완료 후 테스트

---

### 문제 8: CSRF 토큰 에러

**증상**:
```
403 Forbidden: CSRF verification failed
```

**원인**: CSRF_TRUSTED_ORIGINS에 App Runner 도메인 미포함

**해결**:
1. 환경 변수 확인:
   ```
   CSRF_TRUSTED_ORIGINS=https://*.awsapprunner.com
   ```
2. 커스텀 도메인 사용 시 추가:
   ```
   CSRF_TRUSTED_ORIGINS=https://*.awsapprunner.com,https://yourdomain.com
   ```
3. 재배포

---

### 긴급 롤백 방법

배포 후 심각한 문제 발생 시:

1. App Runner 콘솔 → "Activity" 탭
2. 이전 배포 선택 → "Actions" → "Redeploy"
3. 이전 버전으로 롤백 완료

또는 GitHub에서 이전 커밋으로 롤백:
```bash
git revert HEAD
git push origin master
```

---

## 향후 확장

### 트래픽 증가 시 업그레이드 경로

#### 단계 1: App Runner 스케일 업 (100-500명 사용자)
**예상 비용**: $20-40/월

```
App Runner:
- vCPU: 0.25 → 0.5 vCPU
- Memory: 0.5GB → 1GB
- Max size: 10 → 25
```

**방법**:
1. App Runner 콘솔 → Configuration → Edit
2. CPU/Memory 변경
3. Deploy

---

#### 단계 2: 유료 DB/Redis 전환 (500-2000명 사용자)
**예상 비용**: $50-100/월

```
Neon PostgreSQL:
- 무료 계층 → Pro 계층 ($19/월)
- 저장소: 512MB → 10GB
- 컴퓨팅: 공유 → 전용 vCPU

Upstash Redis:
- 무료 계층 → Pro 계층 ($10/월)
- Commands: 10K/day → 무제한
- 메모리: 256MB → 1GB
```

---

#### 단계 3: RDS + ElastiCache 전환 (2000명+ 사용자)
**예상 비용**: $100-200/월

```
AWS RDS PostgreSQL:
- db.t3.small ($30/월)
- 20GB 저장소

AWS ElastiCache Redis:
- cache.t3.micro ($15/월)
- 0.5GB 메모리

CloudFront CDN:
- S3 앞단에 배치
- 전 세계 빠른 전송
```

---

### 웹앱 (PWA) 전환

Progressive Web App으로 변환하여 모바일 홈 화면 추가 지원:

#### 필요한 작업
1. Service Worker 추가
2. manifest.json 생성
3. 오프라인 지원
4. Push 알림 구현

**예상 작업 시간**: 1-2일

---

### Flutter 앱 개발

현재 배포된 서버를 그대로 API 서버로 사용:

#### Flutter 앱 구조
```
Flutter 앱 (모바일)
  ↓ HTTPS REST API
Django 서버 (현재 배포된 서버)
  ↓
PostgreSQL + Redis + S3
```

#### 필요한 작업
1. Flutter 프로젝트 생성
2. HTTP 클라이언트 패키지 추가 (dio, http)
3. WebSocket 클라이언트 추가 (web_socket_channel)
4. 기존 API 엔드포인트 활용
5. UI 개발

**예상 작업 시간**: 2-4주

**장점**:
- 서버 코드 변경 불필요
- API 공유로 개발 속도 향상
- 웹/앱 동시 서비스 가능

---

### 모니터링 및 알림 설정

#### Sentry 통합 (에러 추적)
**무료 계층**: 월 5,000 이벤트

```bash
pip install sentry-sdk

# settings.py
import sentry_sdk
sentry_sdk.init(
    dsn="https://your-sentry-dsn@sentry.io/project-id",
    traces_sample_rate=1.0,
)
```

---

#### AWS CloudWatch 알림
배포 후 CloudWatch에서 자동 생성되는 메트릭:
- CPU 사용률
- 메모리 사용률
- 요청 수
- 응답 시간

**알림 설정 방법**:
1. CloudWatch 콘솔 → Alarms → Create alarm
2. 메트릭 선택 (예: CPU > 80%)
3. 이메일 알림 설정

---

### 백업 전략

#### Neon DB 백업
- 무료 계층: 7일 자동 백업
- Pro 계층: 30일 자동 백업

**수동 백업 방법**:
```bash
pg_dump "postgresql://user:password@host/db" > backup.sql
```

---

#### S3 버전 관리
S3 버킷에서 버전 관리 활성화:
1. S3 콘솔 → 버킷 선택 → Properties
2. "Versioning" → "Enable"
3. 파일 삭제/수정 시 이전 버전 보관

---

## 배포 완료 체크리스트

### ✅ 사전 준비
- [ ] AWS 계정 준비
- [ ] GitHub 계정 준비
- [ ] 로컬 환경 확인 (Python 3.12, Git)

### ✅ 외부 서비스 설정
- [ ] Neon PostgreSQL 데이터베이스 생성
- [ ] DATABASE_URL 복사 및 저장
- [ ] Upstash Redis 인스턴스 생성
- [ ] REDIS_URL 복사 및 저장

### ✅ AWS S3 설정
- [ ] S3 버킷 생성
- [ ] CORS 설정 완료
- [ ] IAM 사용자 생성 및 권한 부여
- [ ] Access Key 발급 및 저장

### ✅ GitHub 준비
- [ ] .gitignore에 .env* 포함 확인
- [ ] 배포 파일 커밋 (apprunner.yaml, deploy.sh 등)
- [ ] GitHub에 푸시 완료

### ✅ AWS App Runner 배포
- [ ] App Runner 서비스 생성
- [ ] GitHub 연결 완료
- [ ] 모든 환경 변수 입력
- [ ] 첫 배포 성공
- [ ] SITE_URL 업데이트 및 재배포

### ✅ 배포 후 검증
- [ ] 홈페이지 접속 확인
- [ ] HTTPS 인증서 확인
- [ ] Admin 패널 접속 확인
- [ ] 슈퍼유저 생성 완료
- [ ] 회원가입 테스트 성공
- [ ] 게시글 작성 및 이미지 업로드 성공
- [ ] 채팅 (WebSocket) 기능 테스트 성공
- [ ] 정적 파일 (CSS/JS) 로딩 확인
- [ ] S3 파일 업로드 확인

### ✅ 추가 설정
- [ ] 비용 모니터링 알림 설정
- [ ] CloudWatch 로그 확인
- [ ] 백업 전략 수립

---

## 도움이 필요하세요?

### 공식 문서
- [AWS App Runner 문서](https://docs.aws.amazon.com/apprunner/)
- [Neon 문서](https://neon.tech/docs/introduction)
- [Upstash 문서](https://docs.upstash.com/)
- [Django 배포 체크리스트](https://docs.djangoproject.com/en/5.1/howto/deployment/checklist/)

### 커뮤니티
- [Django Forum](https://forum.djangoproject.com/)
- [AWS Community](https://repost.aws/)

---

## 다음 단계

배포 완료 후:

1. **사용자 피드백 수집**
   - 웹사이트 공유 및 테스트 요청
   - 버그 리포트 수집

2. **성능 모니터링**
   - CloudWatch 메트릭 확인
   - 사용자 행동 분석

3. **기능 개선**
   - 우선순위 높은 기능 개발
   - 사용자 요청 반영

4. **앱 개발 준비**
   - Flutter 프로젝트 시작
   - API 문서화

---

**🎉 축하합니다! HypeHere 프로덕션 배포가 완료되었습니다!**

이제 웹을 통해 서비스를 제공할 수 있으며, 향후 웹앱 및 Flutter 앱으로 확장할 준비가 되었습니다.
