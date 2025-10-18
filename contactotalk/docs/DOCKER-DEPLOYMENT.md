# Contactotalk Docker 배포 가이드

Docker와 Docker Compose를 사용한 Contactotalk 배포 가이드입니다.

---

## 📋 사전 요구사항

- Docker Engine 20.10+
- Docker Compose 2.0+
- 최소 4GB RAM
- 10GB 디스크 공간

---

## 🚀 로컬 개발 환경 (docker-compose.yml)

### 1. 환경 변수 설정

```bash
# Backend 환경 변수
cp .env.production.example .env.production

# Frontend 환경 변수
cd ../contactotalk-frontend
cp .env.production.example .env.production
```

### 2. Docker Compose로 실행

```bash
# 프로젝트 루트에서
cd /path/to/contactotalk

# 모든 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f backend
```

### 3. 초기 설정

```bash
# 데이터베이스 마이그레이션
docker-compose exec backend python manage.py migrate

# Django superuser 생성
docker-compose exec backend python manage.py createsuperuser

# Static 파일 수집
docker-compose exec backend python manage.py collectstatic --noinput
```

### 4. 접속

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000/api
- **Django Admin**: http://localhost:8000/admin

### 5. 서비스 관리

```bash
# 서비스 중지
docker-compose stop

# 서비스 재시작
docker-compose restart

# 서비스 중지 및 컨테이너 제거
docker-compose down

# 볼륨까지 완전 삭제
docker-compose down -v
```

---

## 🏭 프로덕션 환경 (docker-compose.prod.yml)

### AWS ECS/Fargate 배포 준비

#### 1. ECR 리포지토리 생성

```bash
# AWS CLI로 ECR 리포지토리 생성
aws ecr create-repository --repository-name contactotalk-backend
aws ecr create-repository --repository-name contactotalk-frontend

# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin [ACCOUNT_ID].dkr.ecr.ap-northeast-2.amazonaws.com
```

#### 2. Docker 이미지 빌드 및 푸시

```bash
# 환경 변수 설정
export ECR_REGISTRY=[ACCOUNT_ID].dkr.ecr.ap-northeast-2.amazonaws.com
export IMAGE_TAG=v1.0.0

# Backend 이미지 빌드
docker build -f Dockerfile.backend -t contactotalk-backend:latest .
docker tag contactotalk-backend:latest $ECR_REGISTRY/contactotalk-backend:$IMAGE_TAG
docker tag contactotalk-backend:latest $ECR_REGISTRY/contactotalk-backend:latest
docker push $ECR_REGISTRY/contactotalk-backend:$IMAGE_TAG
docker push $ECR_REGISTRY/contactotalk-backend:latest

# Frontend 이미지 빌드
cd ../contactotalk-frontend
docker build -f Dockerfile.frontend -t contactotalk-frontend:latest .
docker tag contactotalk-frontend:latest $ECR_REGISTRY/contactotalk-frontend:$IMAGE_TAG
docker tag contactotalk-frontend:latest $ECR_REGISTRY/contactotalk-frontend:latest
docker push $ECR_REGISTRY/contactotalk-frontend:$IMAGE_TAG
docker push $ECR_REGISTRY/contactotalk-frontend:latest
```

#### 3. 환경 변수 파일 준비 (.env.prod)

```env
# AWS & Docker
ECR_REGISTRY=[ACCOUNT_ID].dkr.ecr.ap-northeast-2.amazonaws.com
IMAGE_TAG=v1.0.0
AWS_REGION=ap-northeast-2

# Django
SECRET_KEY=your-production-secret-key-min-50-chars
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Database (RDS)
DB_NAME=contactotalk
DB_USER=contactotalk
DB_PASSWORD=your-rds-password
DB_HOST=contactotalk.xxxxx.ap-northeast-2.rds.amazonaws.com
DB_PORT=5432

# Redis (ElastiCache)
REDIS_URL=redis://contactotalk.xxxxx.cache.amazonaws.com:6379/0

# S3 (Static/Media Files)
AWS_STORAGE_BUCKET_NAME=contactotalk-static
AWS_S3_REGION_NAME=ap-northeast-2

# Frontend
NEXT_PUBLIC_API_URL=https://yourdomain.com/api
NEXT_PUBLIC_WS_URL=wss://yourdomain.com/ws
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
```

#### 4. ECS Task Definition 생성

**Backend Task Definition** (`backend-task-def.json`):

```json
{
  "family": "contactotalk-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "[ECR_REGISTRY]/contactotalk-backend:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "DJANGO_ENV", "value": "production"}
      ],
      "secrets": [
        {"name": "SECRET_KEY", "valueFrom": "arn:aws:secretsmanager:..."},
        {"name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:..."}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/contactotalk-backend",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "backend"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/api/health/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 40
      }
    }
  ]
}
```

**Frontend Task Definition** (`frontend-task-def.json`):

```json
{
  "family": "contactotalk-frontend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "frontend",
      "image": "[ECR_REGISTRY]/contactotalk-frontend:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "NODE_ENV", "value": "production"},
        {"name": "NEXT_PUBLIC_API_URL", "value": "https://yourdomain.com/api"},
        {"name": "NEXT_PUBLIC_WS_URL", "value": "wss://yourdomain.com/ws"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/contactotalk-frontend",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "frontend"
        }
      }
    }
  ]
}
```

#### 5. ECS 서비스 생성

```bash
# Backend 서비스
aws ecs create-service \
  --cluster contactotalk-cluster \
  --service-name contactotalk-backend \
  --task-definition contactotalk-backend \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=backend,containerPort=8000"

# Frontend 서비스
aws ecs create-service \
  --cluster contactotalk-cluster \
  --service-name contactotalk-frontend \
  --task-definition contactotalk-frontend \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=frontend,containerPort=3000"
```

---

## 🔄 CI/CD 파이프라인 (GitHub Actions)

### `.github/workflows/deploy-ecs.yml`

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

env:
  AWS_REGION: ap-northeast-2
  ECR_REGISTRY: ${{ secrets.ECR_REGISTRY }}
  ECS_CLUSTER: contactotalk-cluster

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION | \
            docker login --username AWS --password-stdin $ECR_REGISTRY

      - name: Build and push backend
        run: |
          docker build -f Dockerfile.backend -t $ECR_REGISTRY/contactotalk-backend:$GITHUB_SHA .
          docker tag $ECR_REGISTRY/contactotalk-backend:$GITHUB_SHA $ECR_REGISTRY/contactotalk-backend:latest
          docker push $ECR_REGISTRY/contactotalk-backend:$GITHUB_SHA
          docker push $ECR_REGISTRY/contactotalk-backend:latest

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service contactotalk-backend \
            --force-new-deployment
```

---

## 🔧 Docker 이미지 최적화

### 1. 멀티 스테이지 빌드 활용

이미 Dockerfile에 적용되어 있음:
- Builder stage: 의존성 설치 및 빌드
- Production stage: 실행 파일만 복사

### 2. 이미지 크기 최적화

```bash
# 이미지 크기 확인
docker images | grep contactotalk

# 불필요한 이미지 정리
docker image prune -a

# 빌드 캐시 정리
docker builder prune
```

### 3. Layer Caching 활용

- 자주 변경되지 않는 부분(의존성)을 먼저 복사
- 자주 변경되는 부분(소스 코드)을 나중에 복사

---

## 📊 모니터링 및 로깅

### CloudWatch Logs

```bash
# 로그 그룹 생성
aws logs create-log-group --log-group-name /ecs/contactotalk-backend
aws logs create-log-group --log-group-name /ecs/contactotalk-frontend

# 로그 확인
aws logs tail /ecs/contactotalk-backend --follow
```

### Container Insights

```bash
# Container Insights 활성화
aws ecs update-cluster-settings \
  --cluster contactotalk-cluster \
  --settings name=containerInsights,value=enabled
```

---

## 🔐 보안 모범 사례

### 1. Secrets Manager 사용

```bash
# Secret 생성
aws secretsmanager create-secret \
  --name contactotalk/prod/django-secret-key \
  --secret-string "your-secret-key"

# ECS Task Definition에서 참조
"secrets": [
  {
    "name": "SECRET_KEY",
    "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:xxx:secret:contactotalk/prod/django-secret-key"
  }
]
```

### 2. 최소 권한 원칙

- ECS Task Role: 필요한 AWS 서비스만 접근 가능
- Security Group: 필요한 포트만 오픈

### 3. 이미지 스캔

```bash
# ECR 이미지 스캔 활성화
aws ecr put-image-scanning-configuration \
  --repository-name contactotalk-backend \
  --image-scanning-configuration scanOnPush=true
```

---

## 💰 비용 최적화

### 1. Fargate Spot 사용

```json
"capacityProviderStrategy": [
  {
    "capacityProvider": "FARGATE_SPOT",
    "weight": 2
  },
  {
    "capacityProvider": "FARGATE",
    "weight": 1
  }
]
```

### 2. Auto Scaling 설정

```bash
# Target Tracking Scaling Policy
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/contactotalk-cluster/contactotalk-backend \
  --min-capacity 1 \
  --max-capacity 10

aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/contactotalk-cluster/contactotalk-backend \
  --policy-name cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

---

## 🆘 문제 해결

### 컨테이너가 시작되지 않음

```bash
# ECS 태스크 로그 확인
aws ecs describe-tasks --cluster contactotalk-cluster --tasks [task-id]

# CloudWatch Logs 확인
aws logs tail /ecs/contactotalk-backend --follow

# 컨테이너 내부 접속 (디버깅)
aws ecs execute-command \
  --cluster contactotalk-cluster \
  --task [task-id] \
  --container backend \
  --interactive \
  --command "/bin/bash"
```

### Health Check 실패

```bash
# Health check 엔드포인트 확인
curl http://[task-ip]:8000/api/health/

# Health check 설정 확인
aws ecs describe-task-definition --task-definition contactotalk-backend
```

---

## 📚 참고 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [AWS ECS 공식 문서](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate 공식 문서](https://docs.aws.amazon.com/fargate/)
- [Next.js Docker 배포](https://nextjs.org/docs/deployment#docker-image)
