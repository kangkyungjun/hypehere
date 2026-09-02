# EC2 Backend Deployment Guide

## Server Info

| 항목 | 값 |
|------|-----|
| IP | `43.201.45.60` |
| SSH User | `ubuntu` |
| SSH Key | **`secrets/ssh/hypehere-key.pem`** (레포 내부, gitignore됨) |
| App User | `django` |
| Project Path | `/home/django/marketlens/` |
| Service Name | `marketlens-django` |
| Port | `8002` |
| Workers | 3 (gunicorn) |

> ⚠️ **키 위치는 `secrets/ssh/hypehere-key.pem` 하나뿐이다.**
> 과거 이 문서는 `~/Downloads/`를 가리켰는데 그 파일은 없다. 다시 적지 말 것.
> `secrets/`는 `.gitignore` 53행으로 통째 제외되므로 커밋될 위험은 없다.
>
> ```bash
> K=secrets/ssh/hypehere-key.pem   # 모든 예시의 $K
> ```

## Quick Deploy (scp)

서버에 git repo가 없음. 파일 직접 전송 방식.

```bash
# 1. 파일 전송
scp -i secrets/ssh/hypehere-key.pem <local-file> ubuntu@43.201.45.60:/tmp/

# 2. 서버 배치 + 서비스 재시작
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo cp /tmp/<filename> /home/django/marketlens/<target-path> && \
   sudo chown django:django /home/django/marketlens/<target-path> && \
   sudo systemctl restart marketlens-django"

# 3. 상태 확인
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo systemctl status marketlens-django --no-pager"
```

## Example: accounts/views.py 배포

```bash
scp -i secrets/ssh/hypehere-key.pem backend/accounts/views.py ubuntu@43.201.45.60:/tmp/views.py

ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "sudo cp /tmp/views.py /home/django/marketlens/accounts/views.py && \
   sudo chown django:django /home/django/marketlens/accounts/views.py && \
   sudo systemctl restart marketlens-django"
```

## Log Files

```bash
# access log
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "tail -50 /home/django/marketlens_django.log"

# error log
ssh -i secrets/ssh/hypehere-key.pem ubuntu@43.201.45.60 \
  "tail -50 /home/django/marketlens_django_error.log"
```

## Other Services

| Service | Path | Port |
|---------|------|------|
| `fastapi-analytics` | `/home/django/fastapi_analytics/` | `8001` |

## Directory Structure (Server)

```
/home/django/marketlens/
  accounts/
  community/
  marketlens_backend/
  moderation/
  templates/
  venv/
  manage.py
  requirements.txt
```

## Notes

- SSH user는 `ubuntu`이지, `django`가 아님 (django는 앱 실행 유저)
- 서버에 `.git` 없음 -> `git pull` 불가, `scp`로 배포
- `gunicorn` 서비스명은 `marketlens-django`
- Flutter 클라이언트 수정은 앱스토어 재배포 별도 필요
