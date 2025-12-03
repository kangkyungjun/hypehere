# HypeHere AWS 배포 가이드

**프로젝트**: HypeHere - 언어 학습 소셜 플랫폼
**아키텍처**: AWS EC2 + RDS PostgreSQL + ElastiCache Redis + S3
**예상 비용**: 월 $58-70
**배포 시간**: 약 120-180분

## 📋 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [사전 준비](#사전-준비)
3. [Step 0: VPC 및 네트워킹 설정](#step-0-vpc-및-네트워킹-설정)
4. [Step 1: AWS RDS PostgreSQL 설정](#step-1-aws-rds-postgresql-설정)
5. [Step 2: AWS ElastiCache Redis 설정](#step-2-aws-elasticache-redis-설정)
6. [Step 3: AWS S3 설정](#step-3-aws-s3-설정)
7. [Step 4: AWS EC2 인스턴스 설정](#step-4-aws-ec2-인스턴스-설정)
8. [Step 5: Django 애플리케이션 배포](#step-5-django-애플리케이션-배포)
9. [Step 6: Application Load Balancer 설정](#step-6-application-load-balancer-설정)
10. [Step 7: GitHub Actions CI/CD 설정](#step-7-github-actions-cicd-설정)
11. [Step 8: 배포 후 검증](#step-8-배포-후-검증)
12. [문제 해결](#문제-해결)
13. [향후 확장](#향후-확장)

---

## 아키텍처 개요

### 전체 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                    사용자 (웹/모바일)                              │
│              웹 브라우저 | 웹앱 | Flutter 앱                       │
└────────────────────┬────────────────────────────────────────────┘
                     │ HTTPS
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  Application Load Balancer (ALB)                                 │
│  - HTTPS 종료 (SSL/TLS)                                          │
│  - WebSocket 지원                                                │
│  - 헬스 체크                                                      │
│  예상 비용: $20/월                                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS VPC (10.0.0.0/16)                     │
│                                                                   │
│  ┌─────────────────────── Public Subnets ────────────────────┐  │
│  │                                                             │  │
│  │  ┌──────────────────────────────────────────────────────┐ │  │
│  │  │  EC2 Instance (t3.small)                              │ │  │
│  │  │  - Ubuntu 22.04 LTS                                   │ │  │
│  │  │  - Nginx (Reverse Proxy)                             │ │  │
│  │  │  - Django 5.1 + Daphne ASGI                          │ │  │
│  │  │  - Auto Scaling Group (선택사항)                      │ │  │
│  │  │  예상 비용: $15/월                                     │ │  │
│  │  └──────────────────────────────────────────────────────┘ │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────── Private Subnets ───────────────────┐  │
│  │                                                             │  │
│  │  ┌────────────────────┐      ┌──────────────────────────┐ │  │
│  │  │ RDS PostgreSQL 13  │      │ ElastiCache Redis 7.x    │ │  │
│  │  │ db.t3.micro        │      │ cache.t3.micro           │ │  │
│  │  │ Single-AZ          │      │ Single Node              │ │  │
│  │  │ 20GB gp2           │      │                          │ │  │
│  │  │ 예상: $15/월        │      │ 예상: $15/월              │ │  │
│  │  └────────────────────┘      └──────────────────────────┘ │  │
│  │                                                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Security Groups:                                                │
│  - EC2 SG: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (Django)     │
│  - RDS SG: 5432 (PostgreSQL) from EC2 SG                        │
│  - ElastiCache SG: 6379 (Redis) from EC2 SG                     │
│  - ALB SG: 80, 443 from 0.0.0.0/0                               │
└───────────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS S3 (hypehere-static-media)                                  │
│  - Static files (CSS, JS)                                        │
│  - Media uploads (이미지, 파일)                                    │
│  - CORS 설정                                                      │
│  예상 비용: $1-3/월                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 왜 이 아키텍처인가?

#### ✅ 장점
1. **순수 AWS 솔루션**: 외부 서비스 의존성 없음, AWS 통합 관리
2. **확장성**: EC2 Auto Scaling으로 트래픽 증가 대응
3. **안정성**: VPC 내부 Private Subnet으로 DB/Cache 보안 강화
4. **멀티 플랫폼 지원**: 웹/웹앱/Flutter 앱 모두 지원
5. **WebSocket 완벽 지원**: ALB + Daphne로 실시간 채팅 기능
6. **비용 최적화 가능**: Reserved Instance로 30-40% 절감 가능

#### ⚠️ 고려사항
1. **초기 비용**: 월 $58-70 (외부 서비스 대비 3-4배)
2. **서버 관리 필요**: OS 업데이트, 보안 패치, 애플리케이션 배포
3. **설정 복잡도**: VPC, Security Group, Load Balancer 설정 필요
4. **Auto Scaling 설정**: 트래픽 패턴 분석 후 적절한 정책 수립

---

## 사전 준비

### 필요한 계정
- [x] AWS 계정 (이미 보유)
- [ ] GitHub 계정
- [ ] SSH 키 페어 (로컬에 생성 필요)

### 로컬 환경 요구사항
- Python 3.12
- Git
- SSH 클라이언트
- 텍스트 에디터

### 준비 완료 확인
```bash
# 1. Python 버전 확인
python --version  # Python 3.12.x

# 2. Git 상태 확인
git status

# 3. SSH 키 생성 (없는 경우)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 4. requirements.txt 확인
cat requirements.txt | grep -E "Django|daphne|psycopg2|redis|boto3"
```

---

## Step 0: VPC 및 네트워킹 설정

### 0.1. VPC 생성

1. **AWS Console 접속**
   - 서비스 → VPC → "VPC 생성" 클릭

2. **VPC 설정**
   ```
   이름: hypehere-vpc
   IPv4 CIDR: 10.0.0.0/16
   IPv6 CIDR: 없음
   테넌시: 기본값
   DNS 호스트 이름 활성화: ✅
   DNS 확인 활성화: ✅
   ```

### 0.2. Subnet 생성

**Public Subnet (EC2, ALB용)**

```
Subnet 1 (Public):
- 이름: hypehere-public-subnet-1a
- 가용 영역: ap-northeast-2a
- IPv4 CIDR: 10.0.1.0/24

Subnet 2 (Public):
- 이름: hypehere-public-subnet-1b
- 가용 영역: ap-northeast-2b
- IPv4 CIDR: 10.0.2.0/24
```

**Private Subnet (RDS, ElastiCache용)**

```
Subnet 3 (Private):
- 이름: hypehere-private-subnet-1a
- 가용 영역: ap-northeast-2a
- IPv4 CIDR: 10.0.11.0/24

Subnet 4 (Private):
- 이름: hypehere-private-subnet-1b
- 가용 영역: ap-northeast-2b
- IPv4 CIDR: 10.0.12.0/24
```

> **참고**: RDS와 ElastiCache는 최소 2개의 서로 다른 AZ에 있는 서브넷이 필요합니다.

### 0.3. Internet Gateway 생성

1. **Internet Gateway 생성**
   ```
   이름: hypehere-igw
   ```

2. **VPC에 연결**
   - Internet Gateway 선택 → "VPC에 연결" → hypehere-vpc 선택

### 0.4. Route Table 설정

**Public Route Table**

1. **생성**
   ```
   이름: hypehere-public-rt
   VPC: hypehere-vpc
   ```

2. **라우팅 규칙 추가**
   ```
   대상: 0.0.0.0/0
   타겟: hypehere-igw (Internet Gateway)
   ```

3. **Subnet 연결**
   - hypehere-public-subnet-1a 연결
   - hypehere-public-subnet-1b 연결

**Private Route Table**

1. **생성**
   ```
   이름: hypehere-private-rt
   VPC: hypehere-vpc
   ```

2. **Subnet 연결**
   - hypehere-private-subnet-1a 연결
   - hypehere-private-subnet-1b 연결

> **참고**: Private Subnet은 Internet Gateway 연결 없음 (외부 접근 차단)

### 0.5. Security Groups 생성

**ALB Security Group**

```
이름: hypehere-alb-sg
설명: Security group for Application Load Balancer
VPC: hypehere-vpc

인바운드 규칙:
- Type: HTTP, Port: 80, Source: 0.0.0.0/0
- Type: HTTPS, Port: 443, Source: 0.0.0.0/0

아웃바운드 규칙:
- Type: 모든 트래픽, Destination: 0.0.0.0/0
```

**EC2 Security Group**

```
이름: hypehere-ec2-sg
설명: Security group for EC2 Django application
VPC: hypehere-vpc

인바운드 규칙:
- Type: SSH, Port: 22, Source: [내 IP 또는 Bastion IP]
- Type: HTTP, Port: 80, Source: hypehere-alb-sg
- Type: Custom TCP, Port: 8000, Source: hypehere-alb-sg

아웃바운드 규칙:
- Type: 모든 트래픽, Destination: 0.0.0.0/0
```

**RDS Security Group**

```
이름: hypehere-rds-sg
설명: Security group for RDS PostgreSQL
VPC: hypehere-vpc

인바운드 규칙:
- Type: PostgreSQL, Port: 5432, Source: hypehere-ec2-sg

아웃바운드 규칙:
- Type: 모든 트래픽, Destination: 0.0.0.0/0
```

**ElastiCache Security Group**

```
이름: hypehere-elasticache-sg
설명: Security group for ElastiCache Redis
VPC: hypehere-vpc

인바운드 규칙:
- Type: Custom TCP, Port: 6379, Source: hypehere-ec2-sg

아웃바운드 규칙:
- Type: 모든 트래픽, Destination: 0.0.0.0/0
```

### 0.6. 검증

```bash
# AWS CLI로 VPC 확인
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=hypehere-vpc"

# Subnet 확인
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"

# Security Group 확인
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<VPC_ID>"
```

---

## Step 1: AWS RDS PostgreSQL 설정

### 1.1. DB Subnet Group 생성

1. **RDS Console 접속**
   - 서비스 → RDS → "서브넷 그룹" → "DB 서브넷 그룹 생성"

2. **설정**
   ```
   이름: hypehere-db-subnet-group
   설명: Subnet group for HypeHere RDS
   VPC: hypehere-vpc

   서브넷 추가:
   - hypehere-private-subnet-1a (10.0.11.0/24)
   - hypehere-private-subnet-1b (10.0.12.0/24)
   ```

### 1.2. RDS PostgreSQL 인스턴스 생성

1. **"데이터베이스 생성" 클릭**

2. **엔진 선택**
   ```
   엔진 유형: PostgreSQL
   버전: PostgreSQL 15.x (최신 안정 버전)
   템플릿: 프리 티어 (테스트용) 또는 프로덕션 (실사용)
   ```

3. **설정**
   ```
   DB 인스턴스 식별자: hypehere-db
   마스터 사용자 이름: postgres
   마스터 암호: [강력한 암호 생성 - 최소 16자, 특수문자 포함]
   암호 확인: [동일한 암호]
   ```

   > **중요**: 마스터 암호는 반드시 안전한 곳에 저장하세요!

4. **인스턴스 구성**
   ```
   DB 인스턴스 클래스: db.t3.micro (1 vCPU, 1GB RAM)
   스토리지 유형: 범용 SSD (gp2)
   할당된 스토리지: 20GB
   스토리지 자동 조정: ✅ 활성화 (최대 100GB)
   ```

5. **연결**
   ```
   컴퓨팅 리소스: EC2 컴퓨팅 리소스에 연결 안 함
   VPC: hypehere-vpc
   DB 서브넷 그룹: hypehere-db-subnet-group
   퍼블릭 액세스: 아니요 (Private Subnet 사용)
   VPC 보안 그룹: hypehere-rds-sg
   가용 영역: 기본 설정 없음
   ```

6. **추가 구성**
   ```
   초기 데이터베이스 이름: hypehere
   DB 파라미터 그룹: default.postgres15
   백업 보존 기간: 7일
   암호화: ✅ 활성화 (기본 AWS KMS 키)
   성능 개선 도우미: ✅ 활성화
   자동 마이너 버전 업그레이드: ✅ 활성화
   삭제 방지: ✅ 활성화 (프로덕션에만)
   ```

7. **"데이터베이스 생성" 클릭**

   > 생성 완료까지 약 5-10분 소요

### 1.3. 데이터베이스 및 사용자 생성

RDS 인스턴스가 생성되면 애플리케이션용 데이터베이스와 사용자를 생성해야 합니다.

1. **엔드포인트 확인**
   - RDS Console → hypehere-db → "연결 & 보안" 탭
   - 엔드포인트 복사: `hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com`

2. **EC2 Bastion Host 또는 로컬에서 연결 (임시)**

   > **주의**: Private Subnet에 있으므로 직접 연결 불가. EC2 인스턴스 생성 후 진행하거나, 임시로 Public 액세스 활성화

   **임시 Public 액세스 활성화 (선택사항)**
   - RDS Console → hypehere-db → "수정"
   - 퍼블릭 액세스: 예
   - VPC 보안 그룹: 임시로 내 IP 허용
   - "즉시 적용" 선택 → "DB 인스턴스 수정"

3. **psql로 연결**
   ```bash
   # psql 설치 (로컬)
   brew install postgresql  # macOS
   sudo apt install postgresql-client  # Ubuntu

   # RDS 연결
   psql -h hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com \
        -U postgres \
        -d postgres
   ```

4. **애플리케이션 사용자 및 데이터베이스 생성**
   ```sql
   -- 애플리케이션 사용자 생성
   CREATE USER hypehere_app WITH PASSWORD 'your_secure_app_password';

   -- 데이터베이스 생성 (이미 있으면 생략)
   CREATE DATABASE hypehere OWNER hypehere_app;

   -- 권한 부여
   GRANT ALL PRIVILEGES ON DATABASE hypehere TO hypehere_app;

   -- 연결 확인
   \c hypehere
   \du
   \l

   -- 종료
   \q
   ```

5. **Public 액세스 다시 비활성화 (임시 활성화한 경우)**
   - RDS Console → hypehere-db → "수정"
   - 퍼블릭 액세스: 아니요
   - "즉시 적용" → "DB 인스턴스 수정"

### 1.4. 연결 정보 기록

```
RDS 엔드포인트: hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com
포트: 5432
데이터베이스 이름: hypehere
마스터 사용자: postgres
마스터 암호: [저장한 암호]
애플리케이션 사용자: hypehere_app
애플리케이션 암호: your_secure_app_password

DATABASE_URL:
postgresql://hypehere_app:your_secure_app_password@hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com:5432/hypehere
```

---

## Step 2: AWS ElastiCache Redis 설정

### 2.1. Cache Subnet Group 생성

1. **ElastiCache Console 접속**
   - 서비스 → ElastiCache → "서브넷 그룹" → "서브넷 그룹 생성"

2. **설정**
   ```
   이름: hypehere-cache-subnet-group
   설명: Subnet group for HypeHere Redis
   VPC: hypehere-vpc

   서브넷 추가:
   - hypehere-private-subnet-1a (10.0.11.0/24)
   - hypehere-private-subnet-1b (10.0.12.0/24)
   ```

### 2.2. Redis Cluster 생성

1. **"Redis 클러스터 생성" 클릭**

2. **클러스터 설정**
   ```
   클러스터 모드: 비활성화 (단일 노드)
   이름: hypehere-cache
   설명: Redis cache for HypeHere
   엔진 버전: 7.1 (최신 안정 버전)
   포트: 6379 (기본값)
   파라미터 그룹: default.redis7
   노드 유형: cache.t3.micro (0.5GB)
   복제본 수: 0 (Single Node, 비용 절감)
   ```

3. **고급 Redis 설정**
   ```
   서브넷 그룹: hypehere-cache-subnet-group
   Multi-AZ: 비활성화 (복제본 없으므로)
   보안 그룹: hypehere-elasticache-sg
   암호화: 전송 중 암호화 비활성화 (VPC 내부이므로)
   백업: 자동 백업 비활성화 (cache.t3.micro는 지원 안 함)
   ```

4. **"생성" 클릭**

   > 생성 완료까지 약 5-10분 소요

### 2.3. 연결 정보 확인

1. **엔드포인트 확인**
   - ElastiCache Console → Redis → hypehere-cache
   - "기본 엔드포인트" 복사: `hypehere-cache.abc123.0001.use2.cache.amazonaws.com:6379`

2. **연결 정보 기록**
   ```
   Redis 엔드포인트: hypehere-cache.abc123.0001.use2.cache.amazonaws.com
   포트: 6379
   패스워드: 없음 (VPC 내부 보안)

   REDIS_URL:
   redis://hypehere-cache.abc123.0001.use2.cache.amazonaws.com:6379
   ```

### 2.4. 연결 테스트 (EC2 생성 후)

EC2 인스턴스가 생성되면 아래 명령으로 Redis 연결을 테스트합니다.

```bash
# redis-cli 설치
sudo apt install redis-tools -y

# Redis 연결 테스트
redis-cli -h hypehere-cache.abc123.0001.use2.cache.amazonaws.com ping
# 응답: PONG

# 간단한 테스트
redis-cli -h hypehere-cache.abc123.0001.use2.cache.amazonaws.com
> SET test "Hello from HypeHere"
> GET test
> DEL test
> QUIT
```

---

## Step 3: AWS S3 설정

### 3.1. S3 Bucket 생성

1. **S3 Console 접속**
   - 서비스 → S3 → "버킷 만들기"

2. **일반 구성**
   ```
   버킷 이름: hypehere-static-media-[고유번호]
   예: hypehere-static-media-20250103

   AWS 리전: ap-northeast-2 (Seoul)

   객체 소유권: ACL 활성화됨
   ```

3. **퍼블릭 액세스 차단 설정**
   ```
   ☑️ 모든 퍼블릭 액세스 차단: 해제

   ⚠️ 경고 확인: ☑️ 퍼블릭 액세스를 부여할 수 있음을 알고 있습니다.
   ```

4. **버킷 버전 관리**
   ```
   버전 관리: 비활성화 (비용 절감)
   ```

5. **"버킷 만들기" 클릭**

### 3.2. Bucket Policy 설정

1. **버킷 선택 → "권한" 탭**

2. **버킷 정책 편집**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::hypehere-static-media-20250103/*"
       }
     ]
   }
   ```

   > **주의**: `hypehere-static-media-20250103` 부분을 실제 버킷 이름으로 변경하세요.

### 3.3. CORS 설정

1. **버킷 선택 → "권한" 탭 → "CORS(교차 오리진 리소스 공유)" 편집**

2. **CORS 규칙 추가**
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
         "http://localhost:8000",
         "http://127.0.0.1:8000",
         "https://*.amazonaws.com",
         "https://yourdomain.com"
       ],
       "ExposeHeaders": [
         "ETag",
         "x-amz-meta-custom-header"
       ],
       "MaxAgeSeconds": 3000
     }
   ]
   ```

   > **나중에 업데이트**: EC2/ALB 도메인을 `AllowedOrigins`에 추가하세요.

### 3.4. IAM 사용자 및 액세스 키 생성

1. **IAM Console → "사용자" → "사용자 추가"**
   ```
   사용자 이름: hypehere-s3-user
   액세스 유형: 액세스 키 - 프로그래밍 방식 액세스
   ```

2. **권한 설정**
   - "기존 정책 직접 연결" 선택
   - 검색: `AmazonS3FullAccess` 선택

   > **프로덕션 권장**: S3FullAccess 대신 특정 버킷에만 접근 가능한 정책 생성

3. **사용자 생성 완료**
   - **액세스 키 ID**: `AKIA...` (복사)
   - **비밀 액세스 키**: `wJalrXUtn...` (복사)

   > **중요**: 비밀 액세스 키는 이 화면에서만 확인 가능합니다. 안전한 곳에 저장하세요!

### 3.5. 연결 정보 기록

```
S3 버킷 이름: hypehere-static-media-20250103
리전: ap-northeast-2
액세스 키 ID: AKIA...
비밀 액세스 키: wJalrXUtn...

환경변수:
AWS_STORAGE_BUCKET_NAME=hypehere-static-media-20250103
AWS_S3_REGION_NAME=ap-northeast-2
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUtn...
```

---

## Step 4: AWS EC2 인스턴스 설정

### 4.1. EC2 인스턴스 생성

1. **EC2 Console 접속**
   - 서비스 → EC2 → "인스턴스 시작"

2. **이름 및 태그**
   ```
   이름: hypehere-web-server
   ```

3. **애플리케이션 및 OS 이미지 (AMI)**
   ```
   OS: Ubuntu
   AMI: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   아키텍처: 64비트 (x86)
   ```

4. **인스턴스 유형**
   ```
   인스턴스 유형: t3.small (2 vCPU, 2GB RAM)
   ```

   > **참고**: Django + Daphne + Redis Channels 실행에 최소 2GB RAM 권장

5. **키 페어 (로그인)**
   - **새 키 페어 생성**
     ```
     키 페어 이름: hypehere-key
     키 페어 유형: RSA
     프라이빗 키 파일 형식: .pem (SSH 사용)
     ```
   - "키 페어 생성" → `hypehere-key.pem` 다운로드

   > **중요**: 키 파일은 안전한 곳에 저장하고 권한 설정
   ```bash
   chmod 400 hypehere-key.pem
   ```

6. **네트워크 설정**
   ```
   VPC: hypehere-vpc
   서브넷: hypehere-public-subnet-1a
   퍼블릭 IP 자동 할당: 활성화
   방화벽 (보안 그룹): 기존 보안 그룹 선택
   보안 그룹: hypehere-ec2-sg
   ```

7. **스토리지 구성**
   ```
   볼륨 유형: gp3 (General Purpose SSD)
   크기: 20GB
   ```

8. **고급 세부 정보**
   - 나머지는 기본값 유지

9. **"인스턴스 시작" 클릭**

### 4.2. Elastic IP 할당 (선택사항, 권장)

고정 IP 주소를 사용하려면 Elastic IP를 할당합니다.

1. **EC2 Console → "Elastic IP" → "Elastic IP 주소 할당"**
   ```
   네트워크 경계 그룹: ap-northeast-2
   퍼블릭 IPv4 주소 풀: Amazon의 IP 주소 풀
   ```

2. **"할당" 클릭**

3. **Elastic IP 연결**
   - Elastic IP 선택 → "작업" → "Elastic IP 주소 연결"
   - 인스턴스: hypehere-web-server
   - "연결" 클릭

### 4.3. EC2 인스턴스 접속

```bash
# SSH 키 권한 설정 (처음 한 번만)
chmod 400 hypehere-key.pem

# EC2 접속 (Elastic IP 또는 Public IP 사용)
ssh -i hypehere-key.pem ubuntu@<ELASTIC_IP>

# 예시
ssh -i hypehere-key.pem ubuntu@3.134.123.45
```

### 4.4. 시스템 업데이트

```bash
# 패키지 업데이트
sudo apt update
sudo apt upgrade -y

# 필수 패키지 설치
sudo apt install -y python3.12 python3.12-venv python3.12-dev \
                    git nginx postgresql-client redis-tools \
                    build-essential libpq-dev
```

---

## Step 5: Django 애플리케이션 배포

### 5.1. 애플리케이션 사용자 생성

```bash
# 애플리케이션 전용 사용자 생성
sudo useradd -m -s /bin/bash django
sudo passwd django  # 암호 설정

# sudo 권한 부여 (선택사항)
sudo usermod -aG sudo django

# 사용자 전환
sudo su - django
```

### 5.2. 프로젝트 Clone

```bash
# GitHub 프로젝트 Clone
cd ~
git clone https://github.com/kangkyungjun/hypehere.git
cd hypehere

# 또는 Private 저장소인 경우
git clone https://github.com/kangkyungjun/hypehere.git
# GitHub Personal Access Token 입력 필요
```

### 5.3. 가상환경 설정

```bash
# 가상환경 생성
python3.12 -m venv venv

# 가상환경 활성화
source venv/bin/activate

# pip 업그레이드
pip install --upgrade pip

# 의존성 설치
pip install -r requirements.txt
```

### 5.4. 환경변수 설정

```bash
# .env 파일 생성
nano .env
```

**`.env` 파일 내용** (실제 값으로 변경):

```bash
# ==================== Django Configuration ====================
DEBUG=False
DJANGO_SECRET_KEY=your-production-secret-key-here

# Django Secret Key 생성 (한 번 실행)
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Allowed Hosts (ALB DNS 이름, 도메인)
ALLOWED_HOSTS=*.amazonaws.com,yourdomain.com,<EC2_PUBLIC_IP>

# ==================== Site Configuration ====================
SITE_URL=https://your-alb-dns-name.ap-northeast-2.elb.amazonaws.com

# ==================== Email Configuration ====================
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-gmail-app-password

# ==================== Security Configuration ====================
CSRF_TRUSTED_ORIGINS=https://*.amazonaws.com,https://yourdomain.com

# ==================== Database Configuration (RDS) ====================
DATABASE_URL=postgresql://hypehere_app:your_secure_app_password@hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com:5432/hypehere

# ==================== Redis Configuration (ElastiCache) ====================
REDIS_URL=redis://hypehere-cache.abc123.0001.use2.cache.amazonaws.com:6379

# ==================== AWS S3 Configuration ====================
AWS_STORAGE_BUCKET_NAME=hypehere-static-media-20250103
AWS_S3_REGION_NAME=ap-northeast-2
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUtn...
```

> **중요**:
> 1. `DJANGO_SECRET_KEY`는 반드시 새로 생성하세요.
> 2. 모든 `your-*`, `<PLACEHOLDER>` 부분을 실제 값으로 변경하세요.
> 3. `.env` 파일은 절대 Git에 커밋하지 마세요!

### 5.5. 데이터베이스 마이그레이션

```bash
# Static 파일 수집 (S3로 업로드)
python manage.py collectstatic --noinput

# 데이터베이스 마이그레이션
python manage.py migrate

# 슈퍼유저 생성 (선택사항)
python manage.py createsuperuser
```

### 5.6. Gunicorn/Daphne 테스트

```bash
# Daphne로 서버 실행 (테스트)
daphne -b 0.0.0.0 -p 8000 hypehere.asgi:application

# 다른 터미널에서 접속 테스트
curl http://localhost:8000
```

### 5.7. Systemd 서비스 파일 생성

```bash
# 가상환경 비활성화
deactivate

# 사용자 전환 (ubuntu로 돌아가기)
exit

# Systemd 서비스 파일 생성
sudo nano /etc/systemd/system/hypehere.service
```

**`/etc/systemd/system/hypehere.service` 내용**:

```ini
[Unit]
Description=HypeHere Django Application
After=network.target

[Service]
Type=notify
User=django
Group=django
WorkingDirectory=/home/django/hypehere
Environment="PATH=/home/django/hypehere/venv/bin"
EnvironmentFile=/home/django/hypehere/.env
ExecStart=/home/django/hypehere/venv/bin/daphne -b 0.0.0.0 -p 8000 hypehere.asgi:application
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

**서비스 활성화 및 시작**:

```bash
# Systemd 데몬 리로드
sudo systemctl daemon-reload

# 서비스 활성화 (부팅 시 자동 시작)
sudo systemctl enable hypehere

# 서비스 시작
sudo systemctl start hypehere

# 서비스 상태 확인
sudo systemctl status hypehere

# 로그 확인
sudo journalctl -u hypehere -f
```

### 5.8. Nginx 설정

```bash
# Nginx 설정 파일 생성
sudo nano /etc/nginx/sites-available/hypehere
```

**`/etc/nginx/sites-available/hypehere` 내용**:

```nginx
upstream django {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name _;  # ALB가 모든 요청을 전달하므로

    client_max_body_size 100M;

    # Static files (이미 S3에 있으므로 불필요, 하지만 로컬 백업용)
    location /static/ {
        alias /home/django/hypehere/staticfiles/;
    }

    # Media files (S3에 저장되므로 불필요)
    location /media/ {
        alias /home/django/hypehere/media/;
    }

    # WebSocket 지원
    location /ws/ {
        proxy_pass http://django;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # 일반 HTTP 요청
    location / {
        proxy_pass http://django;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
}
```

**Nginx 활성화 및 재시작**:

```bash
# Symlink 생성
sudo ln -s /etc/nginx/sites-available/hypehere /etc/nginx/sites-enabled/

# 기본 설정 비활성화
sudo rm /etc/nginx/sites-enabled/default

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx

# Nginx 상태 확인
sudo systemctl status nginx
```

### 5.9. 방화벽 설정 (UFW)

```bash
# UFW 활성화
sudo ufw enable

# SSH 허용
sudo ufw allow 22/tcp

# HTTP/HTTPS 허용
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 상태 확인
sudo ufw status
```

---

## Step 6: Application Load Balancer 설정

### 6.1. Target Group 생성

1. **EC2 Console → "대상 그룹" → "대상 그룹 생성"**

2. **기본 구성**
   ```
   대상 유형: 인스턴스
   대상 그룹 이름: hypehere-tg
   프로토콜: HTTP
   포트: 80
   VPC: hypehere-vpc
   프로토콜 버전: HTTP1
   ```

3. **상태 검사**
   ```
   상태 검사 프로토콜: HTTP
   상태 검사 경로: /
   고급 상태 검사 설정:
     포트: 트래픽 포트
     정상 임계값: 2
     비정상 임계값: 2
     제한 시간: 5초
     간격: 30초
     성공 코드: 200
   ```

4. **대상 등록**
   - hypehere-web-server 선택 → "아래에 보류 중인 것으로 포함" 클릭

5. **"대상 그룹 생성" 클릭**

### 6.2. Application Load Balancer 생성

1. **EC2 Console → "로드 밸런서" → "로드 밸런서 생성"**

2. **로드 밸런서 유형 선택**
   - "Application Load Balancer" 선택

3. **기본 구성**
   ```
   로드 밸런서 이름: hypehere-alb
   체계: 인터넷 경계
   IP 주소 유형: IPv4
   ```

4. **네트워크 매핑**
   ```
   VPC: hypehere-vpc

   가용 영역 (최소 2개 선택):
   ☑️ ap-northeast-2a - hypehere-public-subnet-1a
   ☑️ ap-northeast-2b - hypehere-public-subnet-1b
   ```

5. **보안 그룹**
   ```
   보안 그룹: hypehere-alb-sg
   ```

6. **리스너 및 라우팅**
   ```
   리스너 1:
   - 프로토콜: HTTP
   - 포트: 80
   - 기본 작업: hypehere-tg로 전달
   ```

   > **HTTPS 리스너는 Step 6.3에서 추가**

7. **"로드 밸런서 생성" 클릭**

### 6.3. HTTPS 리스너 추가 (선택사항, 권장)

**SSL/TLS 인증서가 필요합니다.** AWS Certificate Manager (ACM)에서 무료로 발급 가능합니다.

1. **ACM Console → "인증서 요청"**
   ```
   도메인 이름: yourdomain.com, www.yourdomain.com
   검증 방법: DNS 검증 (권장) 또는 이메일 검증
   ```

2. **인증서 검증 완료 후 → ALB에 HTTPS 리스너 추가**
   - EC2 Console → hypehere-alb → "리스너" 탭 → "리스너 추가"
   ```
   프로토콜: HTTPS
   포트: 443
   기본 작업: hypehere-tg로 전달
   보안 정책: ELBSecurityPolicy-2016-08
   SSL/TLS 인증서: ACM에서 발급받은 인증서 선택
   ```

3. **HTTP → HTTPS 리디렉션 (선택사항)**
   - HTTP 리스너 편집 → "리디렉션" 작업 추가
   ```
   리디렉션 대상: HTTPS
   포트: 443
   상태 코드: 301 (영구 리디렉션)
   ```

### 6.4. DNS 설정 (도메인 사용 시)

Route 53 또는 외부 DNS 제공업체에서 도메인을 ALB DNS 이름으로 CNAME 레코드 설정:

```
yourdomain.com       CNAME   hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com
www.yourdomain.com   CNAME   hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com
```

### 6.5. 환경변수 업데이트

EC2 인스턴스의 `.env` 파일을 ALB DNS 이름으로 업데이트:

```bash
# SSH로 EC2 접속
ssh -i hypehere-key.pem ubuntu@<EC2_IP>

# django 사용자로 전환
sudo su - django
cd hypehere

# .env 파일 편집
nano .env
```

**수정 내용**:
```bash
# ALLOWED_HOSTS에 ALB DNS 이름 추가
ALLOWED_HOSTS=hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com,yourdomain.com,<EC2_IP>

# SITE_URL 변경
SITE_URL=https://hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com

# CSRF_TRUSTED_ORIGINS 업데이트
CSRF_TRUSTED_ORIGINS=https://hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com,https://yourdomain.com
```

**Django 서비스 재시작**:
```bash
# ubuntu 사용자로 전환
exit

# 서비스 재시작
sudo systemctl restart hypehere

# 상태 확인
sudo systemctl status hypehere
```

---

## Step 7: GitHub Actions CI/CD 설정

### 7.1. GitHub Secrets 설정

1. **GitHub 저장소 → Settings → Secrets and variables → Actions**

2. **New repository secret 클릭하여 아래 Secrets 추가**:

```
EC2_HOST: <EC2 Public IP 또는 Elastic IP>
EC2_USER: django
EC2_SSH_KEY: <hypehere-key.pem 파일 내용 전체 복사>
```

### 7.2. GitHub Actions Workflow 생성

프로젝트 루트에 `.github/workflows/deploy.yml` 파일 생성:

```yaml
name: Deploy to EC2

on:
  push:
    branches:
      - master  # 또는 main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Deploy to EC2
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd ~/hypehere
            git pull origin master
            source venv/bin/activate
            pip install -r requirements.txt
            python manage.py collectstatic --noinput
            python manage.py migrate --noinput
            sudo systemctl restart hypehere
            sudo systemctl restart nginx
```

### 7.3. 배포 테스트

```bash
# 로컬에서 변경사항 커밋 및 푸시
git add .github/workflows/deploy.yml
git commit -m "Add GitHub Actions deployment workflow"
git push origin master

# GitHub Actions 탭에서 워크플로우 실행 확인
```

---

## Step 8: 배포 후 검증

### 8.1. ALB 헬스체크 확인

```bash
# EC2 Console → 대상 그룹 → hypehere-tg → "대상" 탭
# 상태: healthy 확인
```

### 8.2. 애플리케이션 접속 테스트

```bash
# 브라우저에서 접속
http://<ALB_DNS_NAME>

# 예시
http://hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com
```

### 8.3. WebSocket 연결 테스트

```javascript
// 브라우저 개발자 도구 Console에서 실행
const ws = new WebSocket('ws://<ALB_DNS_NAME>/ws/test/');
ws.onopen = () => console.log('WebSocket connected');
ws.onmessage = (e) => console.log('Message:', e.data);
ws.onerror = (e) => console.error('WebSocket error:', e);
```

### 8.4. 데이터베이스 연결 확인

```bash
# EC2에 SSH 접속
ssh -i hypehere-key.pem ubuntu@<EC2_IP>

# django 사용자로 전환
sudo su - django
cd hypehere

# Django shell 실행
source venv/bin/activate
python manage.py shell

# 쿼리 테스트
>>> from accounts.models import User
>>> User.objects.count()
0  # 또는 실제 사용자 수
>>> exit()
```

### 8.5. Redis 연결 확인

```bash
# EC2에서 Redis 연결 테스트
redis-cli -h hypehere-cache.abc123.0001.use2.cache.amazonaws.com ping
# 응답: PONG

# Django shell에서 Redis 테스트
python manage.py shell
>>> import redis
>>> from django.conf import settings
>>> r = redis.from_url(settings.CHANNEL_LAYERS['default']['CONFIG']['hosts'][0])
>>> r.ping()
True
>>> r.set('test', 'hello')
True
>>> r.get('test')
b'hello'
>>> exit()
```

### 8.6. Static/Media 파일 확인

```bash
# S3에 파일이 업로드되었는지 확인
aws s3 ls s3://hypehere-static-media-20250103/static/ --recursive | head -20

# 브라우저에서 Static 파일 접속 테스트
https://hypehere-static-media-20250103.s3.ap-northeast-2.amazonaws.com/static/css/components.css
```

---

## 문제 해결

### 문제 1: ALB 헬스체크 실패

**증상**: Target Group에서 EC2 인스턴스 상태가 `unhealthy`

**원인**:
1. Nginx 또는 Django 서비스가 실행되지 않음
2. Security Group에서 ALB → EC2 통신 차단
3. Django가 `/` 경로에서 200 응답을 반환하지 않음

**해결 방법**:

```bash
# 1. 서비스 상태 확인
sudo systemctl status hypehere
sudo systemctl status nginx

# 2. Security Group 확인
# EC2 Console → hypehere-ec2-sg → 인바운드 규칙
# Source: hypehere-alb-sg, Port: 80 확인

# 3. Nginx 로그 확인
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 4. Django 로그 확인
sudo journalctl -u hypehere -f

# 5. 수동 헬스체크 테스트
curl http://localhost:80
```

### 문제 2: RDS 연결 실패

**증상**: `psycopg2.OperationalError: could not connect to server`

**원인**:
1. Security Group에서 EC2 → RDS 통신 차단
2. DATABASE_URL 환경변수 오타
3. RDS 인스턴스가 실행 중이 아님

**해결 방법**:

```bash
# 1. Security Group 확인
# RDS Console → hypehere-db → "연결 & 보안" → 보안 그룹
# 인바운드 규칙: Source = hypehere-ec2-sg, Port = 5432

# 2. 환경변수 확인
cat ~/hypehere/.env | grep DATABASE_URL

# 3. RDS 엔드포인트 직접 연결 테스트
psql -h hypehere-db.c9abc123xyz.ap-northeast-2.rds.amazonaws.com \
     -U hypehere_app \
     -d hypehere

# 4. Django에서 연결 테스트
python manage.py dbshell
```

### 문제 3: ElastiCache 연결 실패

**증상**: `redis.exceptions.ConnectionError: Error connecting to Redis`

**원인**:
1. Security Group에서 EC2 → ElastiCache 통신 차단
2. REDIS_URL 환경변수 오타
3. ElastiCache 클러스터가 실행 중이 아님

**해결 방법**:

```bash
# 1. Security Group 확인
# ElastiCache Console → hypehere-cache → "세부 정보" → 보안 그룹
# 인바운드 규칙: Source = hypehere-ec2-sg, Port = 6379

# 2. 환경변수 확인
cat ~/hypehere/.env | grep REDIS_URL

# 3. Redis 직접 연결 테스트
redis-cli -h hypehere-cache.abc123.0001.use2.cache.amazonaws.com ping

# 4. Telnet으로 포트 확인
telnet hypehere-cache.abc123.0001.use2.cache.amazonaws.com 6379
```

### 문제 4: S3 업로드 실패

**증상**: `ClientError: An error occurred (403) when calling the PutObject operation: Forbidden`

**원인**:
1. IAM 사용자 권한 부족
2. Bucket Policy 오류
3. AWS 액세스 키 환경변수 오타

**해결 방법**:

```bash
# 1. 환경변수 확인
cat ~/hypehere/.env | grep AWS_

# 2. AWS CLI로 직접 테스트
aws s3 cp test.txt s3://hypehere-static-media-20250103/test.txt \
    --region ap-northeast-2

# 3. IAM 사용자 권한 확인
# IAM Console → hypehere-s3-user → "권한" 탭
# AmazonS3FullAccess 정책 연결 확인

# 4. Django에서 collectstatic 재시도
python manage.py collectstatic --noinput -v 2
```

### 문제 5: WebSocket 연결 실패

**증상**: WebSocket 연결 시 `Error: Unexpected server response: 400/404`

**원인**:
1. Nginx에서 WebSocket 프록시 설정 누락
2. Django Channels 설정 오류
3. ALB가 WebSocket 업그레이드를 전달하지 않음

**해결 방법**:

```bash
# 1. Nginx 설정 확인
sudo cat /etc/nginx/sites-available/hypehere | grep -A 10 "/ws/"

# 2. Django Channels 설정 확인
cat ~/hypehere/hypehere/settings.py | grep -A 5 "CHANNEL_LAYERS"

# 3. Nginx 재시작
sudo systemctl restart nginx

# 4. Django 재시작
sudo systemctl restart hypehere

# 5. 로그 확인
sudo journalctl -u hypehere -f
```

### 문제 6: GitHub Actions 배포 실패

**증상**: GitHub Actions 워크플로우에서 SSH 연결 실패

**원인**:
1. GitHub Secrets에 SSH 키가 잘못 설정됨
2. EC2 Public IP가 변경됨 (Elastic IP 미사용)
3. EC2 Security Group에서 GitHub Actions IP 차단

**해결 방법**:

```bash
# 1. GitHub Secrets 확인
# GitHub 저장소 → Settings → Secrets → Actions
# EC2_SSH_KEY가 정확히 설정되었는지 확인

# 2. EC2 Public IP 확인
# EC2 Console → hypehere-web-server → "퍼블릭 IPv4 주소"
# GitHub Secrets의 EC2_HOST 업데이트

# 3. Elastic IP 사용 권장
# EC2 Console → "Elastic IP" → 할당 → 인스턴스에 연결

# 4. SSH 수동 테스트
ssh -i hypehere-key.pem ubuntu@<EC2_IP>
```

### 문제 7: 502 Bad Gateway 오류

**증상**: ALB 접속 시 `502 Bad Gateway` 오류

**원인**:
1. Django/Daphne 서비스가 실행되지 않음
2. Nginx 업스트림 설정 오류
3. Target Group 헬스체크 실패

**해결 방법**:

```bash
# 1. Django 서비스 상태 확인
sudo systemctl status hypehere

# 2. Django 로그 확인
sudo journalctl -u hypehere -n 50

# 3. Nginx 업스트림 확인
sudo cat /etc/nginx/sites-available/hypehere | grep "upstream django"

# 4. Nginx 오류 로그 확인
sudo tail -f /var/log/nginx/error.log

# 5. 서비스 재시작
sudo systemctl restart hypehere
sudo systemctl restart nginx
```

### 문제 8: Static 파일 404 오류

**증상**: CSS/JS 파일이 로드되지 않음 (404 Not Found)

**원인**:
1. collectstatic 실행 안 됨
2. S3 Bucket Policy가 Public Read 허용 안 함
3. STATIC_URL 설정 오류

**해결 방법**:

```bash
# 1. collectstatic 재실행
cd ~/hypehere
source venv/bin/activate
python manage.py collectstatic --noinput

# 2. S3 Bucket Policy 확인
# S3 Console → hypehere-static-media-20250103 → "권한" 탭
# Bucket Policy에서 "s3:GetObject" 허용 확인

# 3. settings.py 확인
cat ~/hypehere/hypehere/settings.py | grep -A 5 "STATIC_URL"

# 4. 브라우저에서 S3 URL 직접 접속 테스트
https://hypehere-static-media-20250103.s3.ap-northeast-2.amazonaws.com/static/css/components.css
```

---

## 향후 확장

### 비용 최적화

#### Reserved Instances
1년 또는 3년 약정으로 30-40% 비용 절감:

```
EC2 t3.small Reserved Instance (1년 선불):
- 온디맨드: $15/월
- Reserved: $9/월
- 절감: $6/월 (40%)

RDS db.t3.micro Reserved Instance (1년 선불):
- 온디맨드: $15/월
- Reserved: $9/월
- 절감: $6/월 (40%)

ElastiCache cache.t3.micro Reserved Instance (1년 선불):
- 온디맨드: $15/월
- Reserved: $9/월
- 절감: $6/월 (40%)

총 절감: $18/월 → 연간 $216
```

#### Savings Plans
더 유연한 비용 절감 옵션:

```
Compute Savings Plans (1년):
- 모든 EC2, Fargate, Lambda에 적용
- 최대 66% 할인
```

### Auto Scaling 설정

트래픽 증가 시 자동으로 EC2 인스턴스 추가:

1. **AMI (Amazon Machine Image) 생성**
   - EC2 Console → hypehere-web-server → "이미지 및 템플릿" → "이미지 생성"

2. **Launch Template 생성**
   ```
   이름: hypehere-lt
   AMI: 위에서 생성한 AMI
   인스턴스 유형: t3.small
   키 페어: hypehere-key
   보안 그룹: hypehere-ec2-sg
   ```

3. **Auto Scaling Group 생성**
   ```
   이름: hypehere-asg
   Launch Template: hypehere-lt
   VPC: hypehere-vpc
   서브넷: hypehere-public-subnet-1a, hypehere-public-subnet-1b

   그룹 크기:
   - 원하는 용량: 2
   - 최소 용량: 1
   - 최대 용량: 5

   조정 정책:
   - 대상 추적 조정
   - 지표: 평균 CPU 사용률
   - 대상 값: 70%
   ```

4. **ALB Target Group 연결**
   - Auto Scaling Group → "로드 밸런싱" → hypehere-tg 연결

### Multi-AZ 고가용성

#### RDS Multi-AZ 배포
```
RDS Console → hypehere-db → "수정"
Multi-AZ 배포: ✅ 활성화
→ 비용: $15/월 → $30/월 (2배)
→ 장점: 자동 장애 조치, 99.95% SLA
```

#### ElastiCache 복제
```
ElastiCache Console → hypehere-cache → "수정"
복제본 수: 1
→ 비용: $15/월 → $30/월 (2배)
→ 장점: 읽기 성능 향상, 자동 장애 조치
```

### CDN (CloudFront) 추가

전 세계 사용자에게 빠른 콘텐츠 전송:

```
CloudFront Console → "배포 생성"
원본 도메인: hypehere-alb-1234567890.ap-northeast-2.elb.amazonaws.com
원본 프로토콜 정책: HTTPS만
뷰어 프로토콜 정책: HTTP를 HTTPS로 리디렉션
가격 등급: 미국, 캐나다, 유럽 사용 (비용 최적화)

예상 비용: $10-20/월 (트래픽 따라)
```

### 모니터링 및 알림

#### CloudWatch 알림 설정
```bash
# AWS CLI로 알림 생성
aws cloudwatch put-metric-alarm \
    --alarm-name hypehere-high-cpu \
    --alarm-description "Alert when CPU exceeds 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --datapoints-to-alarm 2 \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:ap-northeast-2:123456789012:hypehere-alerts
```

#### 로그 집중화 (CloudWatch Logs)
```bash
# EC2에서 CloudWatch Logs 에이전트 설치
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# 설정 파일 생성
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Django 로그를 CloudWatch로 전송
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/config.json
```

### Flutter 앱 지원

Django 백엔드는 이미 REST API + WebSocket을 지원하므로 Flutter 앱에서 바로 사용 가능:

```dart
// Flutter에서 REST API 호출
import 'package:http/http.dart' as http;

final response = await http.get(
  Uri.parse('https://your-alb-dns/api/posts/'),
  headers: {'Authorization': 'Token your_token'},
);

// Flutter에서 WebSocket 연결
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('wss://your-alb-dns/ws/chat/123/'),
);
```

### 데이터베이스 백업 자동화

#### RDS 자동 백업
```
RDS Console → hypehere-db → "수정"
백업 보존 기간: 7일 → 30일 (장기 보관)
백업 시간: 02:00-03:00 (트래픽 적은 시간)
```

#### Manual Snapshot (중요한 시점)
```bash
# AWS CLI로 수동 스냅샷 생성
aws rds create-db-snapshot \
    --db-instance-identifier hypehere-db \
    --db-snapshot-identifier hypehere-db-snapshot-20250103
```

---

## 최종 체크리스트

### 배포 완료 확인
- [ ] VPC, Subnet, Security Group 생성 완료
- [ ] RDS PostgreSQL 생성 및 연결 테스트 완료
- [ ] ElastiCache Redis 생성 및 연결 테스트 완료
- [ ] S3 Bucket 생성 및 Static 파일 업로드 완료
- [ ] EC2 인스턴스 생성 및 SSH 접속 가능
- [ ] Django 애플리케이션 배포 완료
- [ ] Nginx 설정 및 프록시 동작 확인
- [ ] Systemd 서비스 자동 시작 설정 완료
- [ ] ALB 생성 및 헬스체크 통과
- [ ] HTTPS 리스너 설정 (SSL 인증서)
- [ ] GitHub Actions CI/CD 설정 완료
- [ ] WebSocket 연결 테스트 완료
- [ ] Admin 페이지 접속 가능
- [ ] 실시간 채팅 기능 테스트 완료

### 보안 설정 확인
- [ ] RDS Public 액세스 비활성화
- [ ] ElastiCache Private Subnet 배치
- [ ] Security Group 최소 권한 원칙 적용
- [ ] SSH 키 권한 400으로 설정
- [ ] `.env` 파일이 Git에 커밋되지 않음
- [ ] Django SECRET_KEY 프로덕션 전용 생성
- [ ] AWS IAM 액세스 키 안전하게 보관
- [ ] RDS 암호화 활성화
- [ ] HTTPS 강제 리디렉션 설정

### 모니터링 설정 확인
- [ ] CloudWatch 알림 설정
- [ ] CloudWatch Logs 에이전트 설치
- [ ] RDS 성능 개선 도우미 활성화
- [ ] ALB 액세스 로그 활성화 (선택사항)

---

## 참고 자료

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS PostgreSQL Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [AWS ElastiCache Redis Guide](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/5.1/howto/deployment/checklist/)
- [Django Channels Deployment](https://channels.readthedocs.io/en/stable/deploying.html)
- [Nginx Configuration for Django](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

---

**배포 완료!** 🎉

문제가 발생하면 "문제 해결" 섹션을 참고하거나 CloudWatch Logs를 확인하세요.
