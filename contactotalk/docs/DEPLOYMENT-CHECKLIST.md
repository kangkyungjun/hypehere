# Contactotalk 배포 체크리스트

배포 전에 이 체크리스트를 확인하세요.

## ✅ 배포 전 체크리스트

### 1. 코드 준비
- [ ] 모든 기능 테스트 완료
- [ ] 로컬에서 production 모드 테스트
- [ ] Git 커밋 및 푸시 완료
- [ ] requirements.txt 최신 상태 확인
- [ ] package.json dependencies 확인

### 2. 환경 설정
- [ ] `.env.production` 파일 준비
  - [ ] SECRET_KEY 생성 (최소 50자)
  - [ ] DATABASE 정보 입력
  - [ ] ALLOWED_HOSTS 설정
  - [ ] CORS_ALLOWED_ORIGINS 설정
- [ ] Frontend `.env.production` 설정
  - [ ] NEXT_PUBLIC_API_URL 확인
  - [ ] NEXT_PUBLIC_WS_URL 확인

### 3. AWS 설정
- [ ] EC2 인스턴스 생성 완료
- [ ] 보안 그룹 규칙 설정 완료
  - [ ] SSH (22) - 내 IP만 허용
  - [ ] HTTP (80) - 전체 허용
  - [ ] HTTPS (443) - 전체 허용
- [ ] 키 페어 다운로드 및 안전하게 보관
- [ ] Elastic IP 할당 (선택사항)

### 4. 도메인 설정 (선택사항)
- [ ] 도메인 구매 완료
- [ ] DNS A 레코드 설정
- [ ] DNS 전파 확인 (ping 테스트)

## 📦 배포 과정 체크리스트

### Step 1: 서버 접속
- [ ] SSH 키 권한 설정 (chmod 400)
- [ ] SSH 접속 성공
- [ ] 서버 시간대 확인 (UTC 권장)

### Step 2: 프로젝트 업로드
- [ ] Backend 코드 업로드
- [ ] Frontend 코드 업로드
- [ ] 파일 압축 해제
- [ ] 디렉토리 권한 확인

### Step 3: 자동 설치 실행
- [ ] setup-server.sh 실행
- [ ] PostgreSQL 설치 확인
- [ ] Redis 설치 확인
- [ ] Nginx 설치 확인
- [ ] Node.js 설치 확인
- [ ] Python 가상환경 생성 확인

### Step 4: 서비스 구성
- [ ] Gunicorn 서비스 시작
- [ ] Daphne 서비스 시작
- [ ] Celery 서비스 시작
- [ ] Next.js 서비스 시작
- [ ] Nginx 서비스 시작

### Step 5: SSL 설정
- [ ] Let's Encrypt 인증서 발급
- [ ] HTTPS 리다이렉트 확인
- [ ] 인증서 자동 갱신 설정

### Step 6: Django 설정
- [ ] 데이터베이스 마이그레이션
- [ ] Static 파일 수집
- [ ] Superuser 생성
- [ ] Admin 페이지 접속 확인

## ✅ 배포 후 확인사항

### 웹 접속 테스트
- [ ] Frontend 메인 페이지 접속 (https://your-domain.com)
- [ ] Django Admin 접속 (https://your-domain.com/admin)
- [ ] API 엔드포인트 테스트 (https://your-domain.com/api)
- [ ] WebSocket 연결 테스트 (채팅 기능)

### 기능 테스트
- [ ] 회원가입 / 로그인
- [ ] 1:1 채팅 기능
- [ ] 오픈 채팅방 기능
- [ ] 파일 업로드 (프로필 이미지 등)
- [ ] 알림 기능

### 성능 확인
- [ ] 페이지 로딩 속도 (3초 이내)
- [ ] API 응답 속도 (500ms 이내)
- [ ] WebSocket 연결 안정성
- [ ] 이미지 로딩 속도

### 보안 확인
- [ ] HTTPS 강제 리다이렉트
- [ ] Security Headers 확인 (X-Frame-Options 등)
- [ ] SQL Injection 방어 테스트
- [ ] XSS 방어 테스트
- [ ] CORS 설정 확인

### 모니터링 설정
- [ ] 서비스 상태 확인 스크립트
- [ ] 로그 확인 방법 숙지
- [ ] 에러 알림 설정 (선택사항)
- [ ] 백업 스크립트 설정 (선택사항)

## 🔧 문제 발생 시

### 서비스가 시작되지 않는 경우
```bash
# 1. 로그 확인
sudo journalctl -u gunicorn -n 100
sudo journalctl -u daphne -n 100
sudo journalctl -u nginx -n 100

# 2. 설정 파일 확인
nginx -t
python manage.py check --deploy

# 3. 서비스 재시작
sudo systemctl restart gunicorn daphne nginx
```

### 502 Bad Gateway 에러
```bash
# Gunicorn이 실행 중인지 확인
sudo systemctl status gunicorn

# 포트 확인
sudo lsof -i :8000

# Nginx 에러 로그 확인
sudo tail -f /var/log/nginx/error.log
```

### Static 파일이 로드되지 않는 경우
```bash
cd /home/ubuntu/contactotalk
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

## 📊 성능 최적화 체크리스트 (선택사항)

### 데이터베이스
- [ ] RDS로 마이그레이션
- [ ] 데이터베이스 인덱스 최적화
- [ ] 커넥션 풀 설정

### 캐싱
- [ ] ElastiCache Redis 설정
- [ ] Django 캐시 설정
- [ ] CDN 연결 (CloudFront)

### 모니터링
- [ ] CloudWatch 설정
- [ ] Sentry 연동 (에러 추적)
- [ ] APM 도구 연동 (선택사항)

## 🔄 정기 유지보수

### 매일
- [ ] 서비스 상태 확인
- [ ] 에러 로그 확인
- [ ] 디스크 용량 확인

### 매주
- [ ] 보안 업데이트 적용
- [ ] 백업 확인
- [ ] 성능 모니터링

### 매월
- [ ] SSL 인증서 갱신 확인
- [ ] 불필요한 로그 파일 정리
- [ ] 데이터베이스 백업 확인

---

## 📞 긴급 연락처

### AWS 이슈
- AWS Support

### 애플리케이션 이슈
- GitHub Issues
- 개발팀 연락처

---

**축하합니다! 🎉**

모든 체크리스트를 완료했다면 Contactotalk가 성공적으로 배포되었습니다!
