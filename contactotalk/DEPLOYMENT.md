# Contactotalk 배포 가이드

## 🚀 빠른 배포

```bash
./deploy/deploy.sh "커밋 메시지"
```

예시:
```bash
./deploy/deploy.sh "Fix matching status API to return matched_room"
```

## 📋 배포 체크리스트

### 배포 전
- [ ] 로컬에서 모든 기능 테스트 완료
- [ ] `python manage.py check` 통과
- [ ] Migration 파일 생성 및 적용 확인 (`python manage.py makemigrations`)
- [ ] 커밋 메시지 작성
- [ ] 중요 변경사항이면 팀에 공지

### 배포 중
- [ ] `./deploy/deploy.sh "메시지"` 실행
- [ ] 에러 없이 완료되는지 확인

### 배포 후
- [ ] 웹사이트 접속 확인 (http://43.200.129.55:3000)
- [ ] 주요 기능 동작 확인
  - [ ] 로그인/회원가입
  - [ ] 1:1 매칭
  - [ ] 오픈 채팅
  - [ ] 소셜 기능
- [ ] 에러 로그 확인 (필요시)

## 🔧 수동 배포 (문제 발생 시)

### 1. AWS 서버 접속
```bash
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55
```

### 2. 코드 업데이트
```bash
cd /home/ubuntu/contactotalk
git fetch --all
git reset --hard origin/master
```

### 3. Migration 적용
```bash
source venv/bin/activate
python manage.py migrate
```

### 4. 서버 재시작
```bash
pkill -f gunicorn
pkill -f daphne
sleep 2
nohup gunicorn --config deploy/gunicorn.conf.py contactotalk.wsgi:application > /dev/null 2>&1 &
nohup daphne -b 0.0.0.0 -p 8001 contactotalk.asgi:application > /dev/null 2>&1 &
```

## 🔄 롤백 (이전 버전으로 복구)

### 1. Git 히스토리 확인
```bash
git log --oneline -10
```

### 2. 특정 커밋으로 롤백
```bash
git reset --hard <commit-hash>
python manage.py migrate
# 서버 재시작
```

### 3. DB 백업 복구 (필요 시)
```bash
# 백업 목록 확인
ls -lh db.sqlite3.backup.*

# 백업 복구
cp db.sqlite3.backup.YYYYMMDD_HHMMSS db.sqlite3
```

## ❌ 절대 하지 말 것

- `python manage.py flush` ❌ (모든 데이터 삭제)
- `rm db.sqlite3` ❌ (데이터베이스 삭제)
- `python manage.py migrate --fake` ❌ (Migration 건너뛰기)
- 직접 파일 수정 후 Git 없이 배포 ❌

## 📊 데이터베이스 관리

### 백업 확인
```bash
ssh ubuntu@43.200.129.55 "ls -lh /home/ubuntu/contactotalk/db.sqlite3.backup.*"
```

### 수동 백업
```bash
ssh ubuntu@43.200.129.55 "cd /home/ubuntu/contactotalk && cp db.sqlite3 db.sqlite3.backup.\$(date +%Y%m%d_%H%M%S)"
```

## 🐛 문제 해결

### 매칭이 안 돼요
1. Gunicorn 프로세스 확인: `ps aux | grep gunicorn`
2. Migration 상태 확인: `python manage.py showmigrations`
3. 로그 확인: AWS 서버에서 `tail -f logs/gunicorn.log`

### 채팅이 안 돼요
1. Daphne 프로세스 확인: `ps aux | grep daphne`
2. WebSocket 연결 확인: 브라우저 개발자도구 Console 탭
3. Nginx 설정 확인: `/etc/nginx/sites-enabled/contactotalk`

### 관심사가 안 보여요
1. Migration 적용 확인: `python manage.py showmigrations accounts`
2. DB 데이터 확인: `python manage.py shell` → `from accounts.models import Interest; Interest.objects.count()`

## 📞 지원

문제가 지속되면 개발팀에 문의하세요.
