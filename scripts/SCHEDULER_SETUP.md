# 증거 자동 삭제 스케줄러 설정 가이드

채팅 신고 증거를 자동으로 삭제하는 스케줄러 설정 방법입니다.

## 옵션 1: Cron (권장 - 간단한 설정)

### 1. Crontab 편집

```bash
crontab -e
```

### 2. 다음 라인 추가

```bash
# 매일 새벽 2시에 30일 이상 된 증거 자동 삭제
0 2 * * * /usr/local/bin/python3 manage.py delete_old_evidence >> /tmp/evidence_cleanup.log 2>&1

# 또는 특정 Python 가상환경 사용 시:
0 2 * * * cd /Users/kyungjunkang/PycharmProjects/hypehere && /path/to/venv/bin/python manage.py delete_old_evidence >> /tmp/evidence_cleanup.log 2>&1
```

### 3. Crontab 문법 설명

```
┌───────────── 분 (0 - 59)
│ ┌────────────── 시 (0 - 23)
│ │ ┌─────────────── 일 (1 - 31)
│ │ │ ┌──────────────── 월 (1 - 12)
│ │ │ │ ┌───────────────── 요일 (0 - 6) (0 = 일요일)
│ │ │ │ │
0 2 * * *  --> 매일 새벽 2시
```

### 4. 다양한 스케줄 예시

```bash
# 매주 일요일 새벽 3시
0 3 * * 0 cd /path/to/hypehere && python manage.py delete_old_evidence

# 매월 1일 새벽 4시
0 4 1 * * cd /path/to/hypehere && python manage.py delete_old_evidence

# 매일 정오 12시
0 12 * * * cd /path/to/hypehere && python manage.py delete_old_evidence

# 매 6시간마다 (0시, 6시, 12시, 18시)
0 */6 * * * cd /path/to/hypehere && python manage.py delete_old_evidence
```

### 5. 로그 확인

```bash
# 로그 파일 확인
tail -f /tmp/evidence_cleanup.log

# 최근 실행 결과 확인
tail -20 /tmp/evidence_cleanup.log
```

---

## 옵션 2: Celery Beat (프로덕션 환경 권장)

### 1. Celery 및 Redis 설치

```bash
pip install celery redis django-celery-beat
```

### 2. `hypehere/celery.py` 생성

```python
import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')

app = Celery('hypehere')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# 스케줄 설정
app.conf.beat_schedule = {
    'delete-old-evidence-daily': {
        'task': 'chat.tasks.delete_old_evidence_task',
        'schedule': crontab(hour=2, minute=0),  # 매일 새벽 2시
    },
}
```

### 3. `hypehere/__init__.py` 수정

```python
from .celery import app as celery_app

__all__ = ('celery_app',)
```

### 4. `chat/tasks.py` 생성

```python
from celery import shared_task
from django.core.management import call_command

@shared_task
def delete_old_evidence_task():
    """30일 이상 된 증거 자동 삭제"""
    call_command('delete_old_evidence')
```

### 5. `settings.py`에 Celery 설정 추가

```python
# Celery Configuration
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Asia/Seoul'
```

### 6. Celery Worker 및 Beat 실행

```bash
# Terminal 1: Celery Worker 실행
celery -A hypehere worker -l info

# Terminal 2: Celery Beat 실행 (스케줄러)
celery -A hypehere beat -l info
```

### 7. 프로덕션 환경 (Systemd 서비스)

`/etc/systemd/system/celery.service`:
```ini
[Unit]
Description=Celery Service
After=network.target

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/path/to/hypehere
ExecStart=/path/to/venv/bin/celery -A hypehere worker --beat -l info --logfile=/var/log/celery/worker.log --pidfile=/var/run/celery/worker.pid
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 수동 실행 및 테스트

### Dry-run으로 테스트

```bash
# 삭제될 증거 미리보기 (실제 삭제 안 함)
python manage.py delete_old_evidence --dry-run

# 60일 이상 된 증거 삭제 (dry-run)
python manage.py delete_old_evidence --days=60 --dry-run
```

### 실제 삭제 실행

```bash
# 30일 이상 된 증거 삭제
python manage.py delete_old_evidence

# 7일 이상 된 증거 삭제 (짧은 보존 기간)
python manage.py delete_old_evidence --days=7

# 90일 이상 된 증거 삭제 (긴 보존 기간)
python manage.py delete_old_evidence --days=90
```

---

## 권장 설정

### 개발 환경
- **방법**: Cron 사용
- **주기**: 매주 일요일 새벽 3시
- **보존 기간**: 30일

### 프로덕션 환경
- **방법**: Celery Beat 사용
- **주기**: 매일 새벽 2시
- **보존 기간**: 30일 (법적 요구사항에 따라 조정)
- **모니터링**: Celery Flower로 작업 모니터링

---

## 데이터 보존 정책

### GDPR 및 개인정보보호법 준수

- **최소 보존 기간**: 신고 처리 완료 후 7일
- **권장 보존 기간**: 30일
- **최대 보존 기간**: 법적 분쟁 가능성이 있는 경우 90일

### 보존 대상

삭제되는 증거:
- ✅ `message_snapshot` (메시지 내역 JSON)
- ✅ `video_frame` (화상 채팅 캡처 이미지 파일)

보존되는 정보:
- ❌ 신고 기본 정보 (신고자, 피신고자, 신고 사유, 상태)
- ❌ 처리 결과 및 관리자 노트

---

## 문제 해결

### Cron이 실행되지 않을 때

```bash
# Cron 서비스 상태 확인
sudo service cron status

# Cron 로그 확인 (시스템에 따라 경로 다름)
grep CRON /var/log/syslog
# 또는
tail -f /var/log/cron
```

### Python 경로 문제

```bash
# 올바른 Python 경로 확인
which python3

# 가상환경 Python 경로 확인
which python  # 가상환경 활성화 후 실행
```

### 권한 문제

```bash
# 스크립트 실행 권한 부여
chmod +x manage.py

# 로그 디렉토리 권한 확인
ls -la /tmp/evidence_cleanup.log
```

---

## 모니터링

### 정기 점검 사항

1. **로그 확인**: 매주 로그 파일 확인하여 정상 실행 여부 체크
2. **디스크 용량**: 이미지 파일 삭제로 인한 디스크 공간 확보 확인
3. **데이터베이스**: Report 테이블의 NULL 값 증가 확인

### 알림 설정 (선택사항)

Cron 실행 결과를 이메일로 받기:
```bash
MAILTO=admin@example.com
0 2 * * * cd /path/to/hypehere && python manage.py delete_old_evidence
```

---

## 참고자료

- [Django Management Commands](https://docs.djangoproject.com/en/5.1/howto/custom-management-commands/)
- [Crontab Guru](https://crontab.guru/) - Cron 표현식 생성기
- [Celery Documentation](https://docs.celeryproject.org/)
- [GDPR 데이터 보존 정책](https://gdpr.eu/data-retention/)
