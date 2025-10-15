# AWS EC2 배포 가이드

이 가이드를 따라하면 30분 안에 Contactotalk를 AWS에 배포할 수 있습니다.

## 📋 사전 준비사항

- AWS 계정
- 도메인 (선택사항, 없으면 EC2 IP로 접속 가능)
- SSH 클라이언트 (Terminal, PuTTY 등)

## 🚀 Step 1: EC2 인스턴스 생성 (10분)

### 1.1 AWS Console 로그인
1. https://aws.amazon.com/console 접속
2. 로그인
3. 지역 선택: **서울 (ap-northeast-2)** 추천

### 1.2 EC2 인스턴스 시작
1. 서비스 메뉴 → EC2 → "인스턴스 시작" 버튼 클릭

2. **이름 설정**
   - 이름: `contactotalk-server`

3. **AMI 선택**
   - Ubuntu Server 22.04 LTS (무료 티어)

4. **인스턴스 유형 선택**
   - **t3.small** (권장, 월 $15-20)
   - 또는 t2.micro (무료 티어, 테스트용)

5. **키 페어 생성**
   - "새 키 페어 생성" 클릭
   - 이름: `contactotalk-key`
   - 유형: RSA
   - 형식: .pem (Mac/Linux) 또는 .ppk (Windows/PuTTY)
   - **⚠️ 중요**: 키 파일 안전하게 보관!

6. **네트워크 설정**
   - VPC: 기본값
   - 서브넷: 기본값
   - 퍼블릭 IP 자동 할당: **활성화**
   - 보안 그룹 생성:
     ```
     이름: contactotalk-sg
     설명: Contactotalk security group

     인바운드 규칙 추가:
     - SSH (22) - 내 IP
     - HTTP (80) - 0.0.0.0/0
     - HTTPS (443) - 0.0.0.0/0
     - 사용자 지정 TCP (8000) - 0.0.0.0/0 (Django API)
     - 사용자 지정 TCP (3000) - 0.0.0.0/0 (Next.js)
     ```

7. **스토리지 구성**
   - 크기: **30 GB** (권장)
   - 유형: gp3 (SSD)

8. **인스턴스 시작** 버튼 클릭

### 1.3 인스턴스 IP 주소 확인
1. EC2 → 인스턴스 목록에서 생성한 인스턴스 클릭
2. **퍼블릭 IPv4 주소** 복사 (예: 13.125.123.45)

---

## 🔗 Step 2: 도메인 연결 (선택사항, 5분)

### 2.1 도메인이 있는 경우

1. 도메인 등록업체 (가비아, Namecheap 등) 로그인
2. DNS 설정 페이지로 이동
3. A 레코드 추가:
   ```
   호스트: @
   유형: A
   값: [EC2 퍼블릭 IP 주소]
   TTL: 600

   호스트: www
   유형: A
   값: [EC2 퍼블릭 IP 주소]
   TTL: 600
   ```

4. DNS 전파 대기 (5-30분 소요)
5. 확인: `ping your-domain.com`

### 2.2 도메인이 없는 경우

- EC2 IP 주소로 직접 접속 가능
- 나중에 도메인 구매 후 연결 가능

---

## 💻 Step 3: 서버 접속 (2분)

### Mac/Linux:
```bash
# 키 파일 권한 설정
chmod 400 ~/Downloads/contactotalk-key.pem

# SSH 접속
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@[EC2-IP-주소]
```

### Windows (PuTTY):
1. PuTTY 실행
2. Host Name: `ubuntu@[EC2-IP-주소]`
3. Connection → SSH → Auth → Private key file 선택
4. Open 클릭

---

## 📦 Step 4: 프로젝트 업로드 (5분)

### 4.1 로컬에서 프로젝트 압축

```bash
# Backend 압축
cd /Users/kyungjunkang/PycharmProjects
tar -czf contactotalk.tar.gz contactotalk

# Frontend 압축
tar -czf contactotalk-frontend.tar.gz contactotalk-frontend
```

### 4.2 서버로 업로드

```bash
# SCP로 파일 전송
scp -i ~/Downloads/contactotalk-key.pem contactotalk.tar.gz ubuntu@[EC2-IP-주소]:~
scp -i ~/Downloads/contactotalk-key.pem contactotalk-frontend.tar.gz ubuntu@[EC2-IP-주소]:~
```

### 4.3 서버에서 압축 해제

```bash
# SSH 접속 후
cd /home/ubuntu
tar -xzf contactotalk.tar.gz
tar -xzf contactotalk-frontend.tar.gz
```

---

## ⚙️ Step 5: 자동 설치 스크립트 실행 (10분)

### 5.1 설치 스크립트 실행

```bash
cd /home/ubuntu/contactotalk
sudo bash deploy/setup-server.sh your-domain.com
```

> ⚠️ 도메인이 없으면 EC2 IP 주소 사용:
> ```bash
> sudo bash deploy/setup-server.sh 13.125.123.45
> ```

### 5.2 환경 변수 설정

스크립트가 중간에 멈추면:

```bash
# .env.production 파일 편집
nano /home/ubuntu/contactotalk/.env.production
```

**필수 수정 항목:**
```env
# Django Secret Key (새로 생성)
SECRET_KEY=your-new-secret-key-here

# 도메인 설정
ALLOWED_HOSTS=your-domain.com,www.your-domain.com,13.125.123.45

# 데이터베이스 비밀번호 (기본값 사용 가능)
DB_PASSWORD=contactotalk_password_123

# CORS 설정
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com
```

**저장**: `Ctrl + X` → `Y` → `Enter`

---

## ✅ Step 6: 설치 완료 확인 (2분)

### 6.1 서비스 상태 확인

```bash
# 모든 서비스 상태 확인
sudo systemctl status gunicorn
sudo systemctl status daphne
sudo systemctl status nginx
sudo systemctl status nextjs
```

모두 `active (running)` 상태여야 합니다.

### 6.2 웹 브라우저에서 접속

1. **Frontend**: https://your-domain.com
2. **Admin**: https://your-domain.com/admin
3. **API**: https://your-domain.com/api

### 6.3 Django 관리자 계정 생성

```bash
cd /home/ubuntu/contactotalk
source venv/bin/activate
python manage.py createsuperuser
```

---

## 🔧 문제 해결

### 서비스가 시작되지 않는 경우

```bash
# 로그 확인
sudo journalctl -u gunicorn -n 50
sudo journalctl -u daphne -n 50
sudo journalctl -u nginx -n 50

# 서비스 재시작
sudo systemctl restart gunicorn daphne nginx nextjs
```

### SSL 인증서 오류

```bash
# Let's Encrypt 재시도
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### 포트가 이미 사용 중

```bash
# 프로세스 확인
sudo lsof -i :8000
sudo lsof -i :3000

# 강제 종료
sudo kill -9 [PID]
```

---

## 📊 모니터링

### 실시간 로그 보기

```bash
# Django API 로그
tail -f /home/ubuntu/contactotalk/logs/gunicorn_access.log
tail -f /home/ubuntu/contactotalk/logs/gunicorn_error.log

# Nginx 로그
tail -f /var/log/nginx/contactotalk_access.log
tail -f /var/log/nginx/contactotalk_error.log
```

### 서버 리소스 확인

```bash
# CPU, 메모리 사용률
htop

# 디스크 사용량
df -h
```

---

## 🔄 업데이트 방법

### 코드 업데이트

```bash
# 로컬에서 새 코드 업로드
scp -i ~/Downloads/contactotalk-key.pem -r contactotalk ubuntu@[EC2-IP]:~/contactotalk-new

# 서버에서
sudo systemctl stop gunicorn daphne celery nextjs
cd /home/ubuntu/contactotalk
source venv/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl start gunicorn daphne celery nextjs
```

---

## 💰 예상 비용

### 월간 비용 (서울 리전 기준)

- **EC2 t3.small**: $15-20
- **EBS 30GB**: $3
- **데이터 전송**: $5-10 (트래픽에 따라)
- **총 예상**: **$23-33/월**

### 무료 티어 (12개월)

- EC2 t2.micro 750시간/월
- EBS 30GB
- 데이터 전송 15GB/월

---

## 📞 지원

### AWS 관련 문제
- AWS Support Center

### 애플리케이션 문제
- 로그 파일 확인 후 문의

---

## ✨ 다음 단계

1. **모니터링 설정**: CloudWatch 설정
2. **백업 설정**: RDS로 마이그레이션
3. **CDN 설정**: CloudFront 연결
4. **확장**: Auto Scaling 설정

**축하합니다! 🎉 Contactotalk가 성공적으로 배포되었습니다!**
