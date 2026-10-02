# server/ — EC2에서 돌고 있는 서버 코드의 버전 관리 사본

이 디렉터리는 **운영 서버에서 가져온 소스**다. 배포 아티팩트가 아니라
**이력을 남기기 위한 사본**이다.

## 왜 가져왔나

`/home/django/fastapi_analytics`는 **git 저장소가 아니었다.**
그 결과 `app/`에 수동 백업이 쌓여 있었다:

```
_schemas.py.bak.20260621_085004
_schemas.py.bak.20260621_091333
_schemas.py.bak.20260621_092424
_schemas.py.bak.20260621_102323
_schemas.py.bak.20260628_155705
_schemas.py.bak.20260628_161507
_schemas.py.bak.20260628_165435
_models.py.bak.*  (3개)
_admin.py.bak.*   (4개)
...
```

롤백 수단이 백업 파일뿐이라, "어느 백업이 어느 시점인지"를 **파일명으로**
추적해야 했다. 일부는 `root` 소유라 서비스 계정(`django`)이 지우지도 못한다.

## 동기화

```bash
# 서버 → 로컬 (현재 상태를 당겨온다)
rsync -az --delete \
  -e "ssh -i secrets/ssh/hypehere-key.pem" \
  --rsync-path="sudo rsync" \
  --exclude='venv/' --exclude='__pycache__/' --exclude='*.pyc' \
  --exclude='.env' --exclude='*.bak*' --exclude='_*bak*' --exclude='*.log' \
  ubuntu@43.201.45.60:/home/django/fastapi_analytics/ \
  server/fastapi_analytics/
```

**`.env`는 절대 가져오지 않는다.** DB 자격증명이 들어 있다.
`app/config.py`는 필드 선언만 있고 값은 `.env`에서 읽으므로 안전하다.

## 주의

- 이 사본을 고쳐도 **서버에 자동 반영되지 않는다.** 서버 쪽 적용은 별도다.
- 서버를 직접 고쳤다면 **다시 당겨와서 커밋**해야 이력이 맞는다.
  그러지 않으면 사본이 거짓말을 하게 된다.

## 구성

| 서비스 | 포트 | 경로 |
|---|--:|---|
| analytics (FastAPI) | 8001 | `fastapi_analytics/` ← 이 디렉터리 |
| community (Django) | 8000 | 레포 루트 `backend/` |
| accounts (Django) | 8002 | 레포 루트 `backend/` |

DB: RDS Postgres `hypehere`, 스키마 `analytics`
