# Contactotalk 문제 해결 가이드

배포 및 운영 중 발생할 수 있는 일반적인 문제와 해결 방법입니다.

---

## 🚨 서비스 시작 실패

### 문제: Gunicorn이 시작되지 않음

**증상**:
```bash
sudo systemctl status gunicorn
● gunicorn.service - failed
```

**해결 방법**:

1. **로그 확인**:
```bash
sudo journalctl -u gunicorn -n 100
```

2. **일반적인 원인**:

**a) 환경 변수 누락**:
```bash
# .env.production 파일 확인
cd /home/ubuntu/contactotalk
cat .env.production

# SECRET_KEY, DB_PASSWORD 등이 설정되어 있는지 확인
```

**b) 데이터베이스 연결 실패**:
```bash
# PostgreSQL 상태 확인
sudo systemctl status postgresql

# PostgreSQL 재시작
sudo systemctl restart postgresql

# 데이터베이스 연결 테스트
sudo -u postgres psql -d contactotalk -c "SELECT 1;"
```

**c) 가상환경 문제**:
```bash
# 가상환경 재생성
cd /home/ubuntu/contactotalk
rm -rf venv
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.production.txt
```

**d) 포트 충돌**:
```bash
# 포트 8000 사용 확인
sudo lsof -i :8000

# 프로세스 종료
sudo kill -9 [PID]
```

3. **서비스 재시작**:
```bash
sudo systemctl restart gunicorn
sudo systemctl status gunicorn
```

---

## 🌐 502 Bad Gateway

### 문제: Nginx에서 502 에러 발생

**증상**: 브라우저에서 "502 Bad Gateway" 표시

**해결 방법**:

1. **백엔드 서비스 상태 확인**:
```bash
# 모든 서비스 상태 확인
sudo systemctl status gunicorn
sudo systemctl status daphne
sudo systemctl status nextjs

# 실행 중이 아닌 서비스가 있다면 시작
sudo systemctl start gunicorn daphne nextjs
```

2. **Nginx 에러 로그 확인**:
```bash
sudo tail -f /var/log/nginx/contactotalk_error.log
```

3. **일반적인 원인**:

**a) Gunicorn이 응답하지 않음**:
```bash
# Gunicorn 재시작
sudo systemctl restart gunicorn

# 포트 확인
sudo lsof -i :8000
```

**b) Unix 소켓 권한 문제**:
```bash
# Nginx 설정 확인
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

**c) Next.js 서비스 중지**:
```bash
# Next.js 재시작
sudo systemctl restart nextjs

# 포트 확인
sudo lsof -i :3000
```

4. **모든 서비스 재시작**:
```bash
sudo systemctl restart gunicorn daphne nextjs nginx
```

---

## 🔒 SSL 인증서 문제

### 문제: SSL 인증서 오류

**증상**: "Your connection is not private" 또는 인증서 만료

**해결 방법**:

1. **인증서 상태 확인**:
```bash
sudo certbot certificates
```

2. **인증서 갱신**:
```bash
# 수동 갱신
sudo certbot renew

# 특정 도메인 재발급
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

3. **자동 갱신 설정 확인**:
```bash
# certbot timer 확인
sudo systemctl status certbot.timer

# timer 활성화
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

4. **갱신 테스트**:
```bash
sudo certbot renew --dry-run
```

---

## 📁 Static 파일 로딩 실패

### 문제: CSS/JS/이미지가 로드되지 않음

**증상**: 웹사이트 스타일이 깨지거나 이미지가 표시되지 않음

**해결 방법**:

1. **Static 파일 재수집**:
```bash
cd /home/ubuntu/contactotalk
source venv/bin/activate
export DJANGO_ENV=production
python manage.py collectstatic --noinput
```

2. **디렉토리 권한 확인**:
```bash
# static 디렉토리 권한 설정
sudo chown -R ubuntu:ubuntu /home/ubuntu/contactotalk/staticfiles
sudo chmod -R 755 /home/ubuntu/contactotalk/staticfiles
```

3. **Nginx 설정 확인**:
```bash
# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

4. **브라우저 캐시 클리어**:
- Ctrl + F5 (강제 새로고침)
- 브라우저 개발자 도구 → Network 탭 → "Disable cache" 체크

---

## 🔌 WebSocket 연결 실패

### 문제: 실시간 채팅이 작동하지 않음

**증상**: 메시지가 실시간으로 전송되지 않음

**해결 방법**:

1. **Daphne 서비스 확인**:
```bash
sudo systemctl status daphne
sudo journalctl -u daphne -n 50
```

2. **Redis 연결 확인**:
```bash
# Redis 상태 확인
sudo systemctl status redis-server

# Redis 연결 테스트
redis-cli ping
# 응답: PONG

# Redis 재시작
sudo systemctl restart redis-server
```

3. **Nginx WebSocket 설정 확인**:
```bash
# Nginx 설정 확인
sudo cat /etc/nginx/sites-available/contactotalk | grep -A 10 "location /ws/"

# Nginx 재시작
sudo systemctl restart nginx
```

4. **방화벽 설정 확인**:
```bash
# AWS Security Group에서 다음 포트가 열려있는지 확인:
# - 443 (HTTPS/WSS)
# - 80 (HTTP)
```

---

## 💾 데이터베이스 문제

### 문제: 데이터베이스 연결 실패

**증상**: "could not connect to server" 또는 "FATAL: database does not exist"

**해결 방법**:

1. **PostgreSQL 상태 확인**:
```bash
sudo systemctl status postgresql
sudo systemctl restart postgresql
```

2. **데이터베이스 존재 확인**:
```bash
sudo -u postgres psql -l | grep contactotalk
```

3. **데이터베이스가 없다면 생성**:
```bash
sudo -u postgres psql <<EOF
CREATE DATABASE contactotalk;
CREATE USER contactotalk WITH PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE contactotalk TO contactotalk;
\q
EOF
```

4. **마이그레이션 실행**:
```bash
cd /home/ubuntu/contactotalk
source venv/bin/activate
export DJANGO_ENV=production
python manage.py migrate
```

5. **연결 설정 확인**:
```bash
# .env.production 파일 확인
cat /home/ubuntu/contactotalk/.env.production | grep DB_
```

---

## 🧹 디스크 용량 부족

### 문제: "No space left on device"

**증상**: 서비스 실패, 로그 기록 불가

**해결 방법**:

1. **디스크 사용량 확인**:
```bash
df -h
du -sh /var/log/*
du -sh /home/ubuntu/*
```

2. **로그 파일 정리**:
```bash
# Nginx 로그 정리 (7일 이상 된 로그)
sudo find /var/log/nginx/ -name "*.log" -mtime +7 -delete

# 시스템 로그 정리
sudo journalctl --vacuum-time=7d

# Django 로그 정리
sudo find /home/ubuntu/contactotalk/logs/ -name "*.log" -mtime +7 -delete
```

3. **불필요한 패키지 제거**:
```bash
sudo apt autoremove
sudo apt autoclean
```

4. **Docker 이미지/컨테이너 정리** (Docker 사용 시):
```bash
docker system prune -a
```

---

## 🔄 서비스 자동 재시작 실패

### 문제: 서버 재부팅 후 서비스가 시작되지 않음

**해결 방법**:

1. **systemd 서비스 활성화 확인**:
```bash
sudo systemctl is-enabled gunicorn
sudo systemctl is-enabled daphne
sudo systemctl is-enabled celery
sudo systemctl is-enabled nextjs
sudo systemctl is-enabled nginx
sudo systemctl is-enabled postgresql
sudo systemctl is-enabled redis-server
```

2. **서비스 활성화**:
```bash
sudo systemctl enable gunicorn daphne celery nextjs nginx postgresql redis-server
```

3. **서비스 시작 순서 확인**:
```bash
# service 파일에서 After 디렉티브 확인
sudo cat /etc/systemd/system/gunicorn.service | grep After

# 필요시 수정
sudo nano /etc/systemd/system/gunicorn.service

# systemd 재로드
sudo systemctl daemon-reload
```

---

## 📊 성능 문제

### 문제: 응답 속도가 느림

**해결 방법**:

1. **서버 리소스 확인**:
```bash
# CPU, 메모리 사용률
htop

# 디스크 I/O
iostat -x 1

# 네트워크
iftop
```

2. **데이터베이스 쿼리 최적화**:
```bash
# Django Debug Toolbar 활성화 (개발 환경에서)
# slow query 로그 확인
sudo tail -f /var/log/postgresql/postgresql-*.log
```

3. **Gunicorn 워커 수 조정**:
```bash
# gunicorn.conf.py 수정
sudo nano /home/ubuntu/contactotalk/deploy/gunicorn.conf.py

# workers = (2 * CPU_COUNT) + 1
# 예: 2 CPU → workers = 5

# 재시작
sudo systemctl restart gunicorn
```

4. **Redis 캐시 확인**:
```bash
# Redis 상태 확인
redis-cli info stats
redis-cli info memory
```

---

## 🐛 디버깅 팁

### 로그 확인 방법

**1. 시스템 서비스 로그**:
```bash
# 실시간 로그 보기
sudo journalctl -u gunicorn -f
sudo journalctl -u daphne -f
sudo journalctl -u nextjs -f

# 최근 100줄
sudo journalctl -u gunicorn -n 100

# 특정 시간 이후
sudo journalctl -u gunicorn --since "1 hour ago"
```

**2. Nginx 로그**:
```bash
# Access log
sudo tail -f /var/log/nginx/contactotalk_access.log

# Error log
sudo tail -f /var/log/nginx/contactotalk_error.log
```

**3. Django 로그**:
```bash
# Application 로그
sudo tail -f /home/ubuntu/contactotalk/logs/gunicorn_error.log
```

**4. PostgreSQL 로그**:
```bash
sudo tail -f /var/log/postgresql/postgresql-*.log
```

---

## 🆘 긴급 복구

### 모든 서비스 재시작

```bash
#!/bin/bash
# 모든 서비스 재시작 스크립트

echo "Restarting all services..."

sudo systemctl restart postgresql
sleep 2

sudo systemctl restart redis-server
sleep 2

sudo systemctl restart gunicorn
sudo systemctl restart daphne
sudo systemctl restart celery
sudo systemctl restart nextjs
sudo systemctl restart nginx

echo "Checking service status..."
sudo systemctl status gunicorn --no-pager
sudo systemctl status daphne --no-pager
sudo systemctl status nextjs --no-pager
sudo systemctl status nginx --no-pager

echo "Done!"
```

### 백업에서 복구

```bash
# 데이터베이스 백업에서 복구
gunzip < /home/ubuntu/backups/contactotalk_YYYYMMDD_HHMMSS.sql.gz | sudo -u postgres psql contactotalk

# 마이그레이션 다시 실행
cd /home/ubuntu/contactotalk
source venv/bin/activate
export DJANGO_ENV=production
python manage.py migrate
```

---

## 📞 추가 지원

### AWS 관련 문제
- AWS Support Center
- AWS 문서: https://docs.aws.amazon.com/

### 애플리케이션 문제
- 프로젝트 GitHub Issues
- 로그 파일 수집 후 문의

---

## ✅ 체크리스트

문제 발생 시 다음 순서로 확인:

1. ☐ 모든 서비스 상태 확인 (`systemctl status`)
2. ☐ 로그 파일 확인 (`journalctl`, `/var/log`)
3. ☐ 디스크 공간 확인 (`df -h`)
4. ☐ 포트 사용 확인 (`lsof -i :PORT`)
5. ☐ 네트워크 연결 확인 (`ping`, `curl`)
6. ☐ 데이터베이스 연결 확인
7. ☐ Redis 연결 확인
8. ☐ 환경 변수 설정 확인
9. ☐ 서비스 재시작 시도
10. ☐ 서버 재부팅 고려 (마지막 수단)
