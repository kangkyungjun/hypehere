# Contact

otalk - AWS 배포 가이드

## 🎯 빠른 시작 (30분 완성)

### 1단계: EC2 인스턴스 준비 (10분)
```bash
# AWS Console에서:
1. EC2 인스턴스 생성 (Ubuntu 22.04, t3.small)
2. 보안 그룹: SSH(22), HTTP(80), HTTPS(443) 오픈
3. 키 페어 다운로드
```

### 2단계: 프로젝트 업로드 (5분)
```bash
# 로컬 컴퓨터에서:
cd /Users/kyungjunkang/PycharmProjects
tar -czf contactotalk.tar.gz contactotalk
tar -czf contactotalk-frontend.tar.gz contactotalk-frontend

# 서버로 전송
scp -i your-key.pem contactotalk*.tar.gz ubuntu@[EC2-IP]:~
```

### 3단계: 서버에서 설치 (15분)
```bash
# SSH 접속
ssh -i your-key.pem ubuntu@[EC2-IP]

# 압축 해제
tar -xzf contactotalk.tar.gz
tar -xzf contactotalk-frontend.tar.gz

# 자동 설치 실행 (마법의 한 줄!)
cd contactotalk
sudo bash deploy/setup-server.sh your-domain.com
```

**끝! 🎉** 이제 `https://your-domain.com` 으로 접속하세요!

---

## 📂 배포 파일 구조

```
contactotalk/
├── deploy/
│   ├── nginx.conf              # Nginx 웹 서버 설정
│   ├── gunicorn.conf.py        # Django API 서버 설정
│   ├── gunicorn.service        # Gunicorn 자동 시작 설정
│   ├── daphne.service          # WebSocket 서버 설정
│   ├── celery.service          # 백그라운드 작업 설정
│   ├── nextjs.service          # Next.js 프론트엔드 설정
│   └── setup-server.sh         # 🌟 마스터 설치 스크립트
│
├── docs/
│   ├── AWS-SETUP-GUIDE.md      # 📖 상세 AWS 설정 가이드
│   ├── DEPLOYMENT-CHECKLIST.md # ✅ 배포 체크리스트
│   └── TROUBLESHOOTING.md      # 🔧 문제 해결 가이드 (예정)
│
├── contactotalk/settings/
│   ├── __init__.py             # 환경별 설정 자동 로드
│   ├── base.py                 # 기본 설정
│   └── production.py           # 프로덕션 설정
│
├── .env.production.example     # 환경 변수 템플릿
└── requirements.production.txt # 프로덕션 의존성
```

---

## 🚀 배포 아키텍처

```
Internet
    ↓
Nginx (포트 80/443) - SSL 인증서
    ├─→ Gunicorn (포트 8000) - Django REST API
    ├─→ Daphne (포트 8001) - WebSocket (채팅)
    └─→ Next.js (포트 3000) - Frontend
    ↓
PostgreSQL (포트 5432) - 데이터베이스
Redis (포트 6379) - 캐시 & WebSocket
Celery - 백그라운드 작업
```

---

## 📋 필수 요구사항

### AWS
- EC2 인스턴스 (최소 t3.small, 2GB RAM)
- 30GB 스토리지
- 퍼블릭 IP 주소
- 보안 그룹 포트: 22, 80, 443

### 로컬 환경
- SSH 클라이언트
- 프로젝트 소스 코드
- (선택) 도메인

---

## ⚙️ 자동 설치 스크립트가 하는 일

`setup-server.sh` 스크립트는 다음을 자동으로 수행합니다:

1. ✅ 시스템 업데이트
2. ✅ Python 3.11 설치
3. ✅ PostgreSQL 설치 및 데이터베이스 생성
4. ✅ Redis 설치 및 설정
5. ✅ Node.js 18 설치
6. ✅ Nginx 설치 및 설정
7. ✅ Django 가상환경 생성
8. ✅ Python 패키지 설치
9. ✅ Next.js 빌드
10. ✅ Systemd 서비스 등록 및 시작
11. ✅ SSL 인증서 자동 발급 (Let's Encrypt)
12. ✅ 모든 서비스 자동 시작 설정

**단 한 줄의 명령어로 모든 것이 자동으로 설정됩니다!**

---

## 🔑 환경 변수 설정

배포 전에 `.env.production` 파일을 수정하세요:

```bash
# Django 설정
SECRET_KEY=your-super-secret-key-min-50-chars
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your-ec2-ip

# 데이터베이스
DB_NAME=contactotalk
DB_USER=contactotalk
DB_PASSWORD=your-secure-password
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_URL=redis://127.0.0.1:6379/0

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# SSL
SECURE_SSL_REDIRECT=True
```

---

## 🔄 업데이트 방법

### 코드 업데이트
```bash
# 서버에서
cd /home/ubuntu/contactotalk
source venv/bin/activate

# 새 코드 가져오기 (Git 사용 시)
git pull origin main

# 또는 SCP로 전송
# scp -i key.pem updated-files.tar.gz ubuntu@[EC2-IP]:~

# 마이그레이션 & Static 파일
python manage.py migrate
python manage.py collectstatic --noinput

# 서비스 재시작
sudo systemctl restart gunicorn daphne celery
```

### Frontend 업데이트
```bash
cd /home/ubuntu/contactotalk-frontend
npm run build
sudo systemctl restart nextjs
```

---

## 📊 서비스 관리

### 상태 확인
```bash
# 모든 서비스 상태
sudo systemctl status gunicorn daphne celery nextjs nginx

# 개별 서비스 상태
sudo systemctl status gunicorn
```

### 서비스 제어
```bash
# 재시작
sudo systemctl restart gunicorn

# 중지
sudo systemctl stop gunicorn

# 시작
sudo systemctl start gunicorn

# 자동 시작 활성화
sudo systemctl enable gunicorn
```

### 로그 확인
```bash
# 실시간 로그 보기
sudo journalctl -u gunicorn -f

# 최근 100줄
sudo journalctl -u gunicorn -n 100

# Nginx 로그
sudo tail -f /var/log/nginx/contactotalk_access.log
sudo tail -f /var/log/nginx/contactotalk_error.log
```

---

## 🆘 문제 해결

### 502 Bad Gateway
```bash
# Gunicorn 상태 확인
sudo systemctl status gunicorn

# 재시작
sudo systemctl restart gunicorn nginx
```

### Static 파일이 안 보임
```bash
cd /home/ubuntu/contactotalk
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

### WebSocket 연결 실패
```bash
# Daphne 상태 확인
sudo systemctl status daphne

# Redis 확인
redis-cli ping  # PONG 응답 확인

# 재시작
sudo systemctl restart daphne
```

### SSL 인증서 오류
```bash
# 인증서 재발급
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# 인증서 갱신 테스트
sudo certbot renew --dry-run
```

---

## 💰 예상 비용

### 초기 설정 (EC2 단일 서버)
- **EC2 t3.small**: $15-20/월
- **EBS 30GB**: $3/월
- **데이터 전송**: $5-10/월
- **총**: **약 $25-35/월**

### 확장 시 (사용자 증가)
- **RDS PostgreSQL**: +$15-30/월
- **ElastiCache Redis**: +$15-20/월
- **CDN (CloudFront)**: +$5-10/월
- **총**: **약 $60-95/월**

---

## 📚 추가 문서

- **[AWS 설정 가이드](docs/AWS-SETUP-GUIDE.md)** - AWS Console 사용법
- **[배포 체크리스트](docs/DEPLOYMENT-CHECKLIST.md)** - 배포 전후 확인사항
- **[문제 해결 가이드](docs/TROUBLESHOOTING.md)** - 일반적인 문제 해결법

---

## 🎓 다음 단계

### 필수
1. Django Superuser 생성
2. DNS 설정 확인
3. SSL 인증서 확인
4. 기능 테스트

### 권장
1. 백업 설정
2. 모니터링 설정 (CloudWatch)
3. 에러 추적 (Sentry)
4. CDN 설정

### 확장 시
1. RDS로 데이터베이스 마이그레이션
2. ElastiCache Redis 사용
3. Auto Scaling 설정
4. Multi-Region 배포

---

## 📞 지원

### 긴급 문제
1. 로그 파일 확인
2. 서비스 재시작
3. GitHub Issues 등록

### AWS 문제
- AWS Support Center

---

## ✨ 축하합니다!

**Contact

otalk가 성공적으로 배포되었습니다!** 🎉

이제 전 세계 사용자들이 여러분의 서비스를 사용할 수 있습니다.

```bash
# 접속 URL
https://your-domain.com        # Frontend
https://your-domain.com/admin  # Django Admin
https://your-domain.com/api    # REST API
```

**Happy Coding! 🚀**
