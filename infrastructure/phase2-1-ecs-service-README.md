# Phase 2-1: ECS 서비스 생성

## 생성된 리소스

### 1. ECS Task Definition
- **Family**: ci-cd-demo-service
- **CPU/Memory**: 256 CPU, 512 MB Memory
- **Network Mode**: awsvpc (Fargate)
- **Container**: app (포트 8080)

### 2. ECS Service
- **Service Name**: ci-cd-demo-service
- **Desired Count**: 1개 컨테이너
- **Launch Type**: Fargate
- **Deployment Controller**: ECS
- **Load Balancer**: Blue Target Group에 연결

## 배포 전 필수 작업: 첫 번째 이미지 푸시

### 1. ECR 로그인
```bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com
```

### 2. 이미지 빌드 및 푸시 (AMD64 플랫폼)
```bash
# 프로젝트 루트에서 실행
docker build --platform linux/amd64 -t ci-cd-demo-app .
docker tag ci-cd-demo-app:latest ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/ci-cd-demo-app:latest
docker push 277707126943.dkr.ecr.ap-northeast-2.amazonaws.com/ci-cd-demo-app:latest
```

**ACCOUNT_ID를 실제 AWS 계정 ID로 교체하세요.**

## 배포 방법

```bash
cd infrastructure
./phase2-1-deploy.sh
```

## 배포 후 확인사항

### 1. ECS 서비스 상태
- ECS 콘솔 → 클러스터 → ci-cd-demo-cluster → 서비스 탭
- **Running tasks**: 1/1 (정상)
- **Service status**: ACTIVE

### 2. 애플리케이션 접근
- ALB DNS Name으로 접근 (Phase 1 CloudFormation 출력값)
- `http://ALB_DNS_NAME` → "Hello World!" 페이지 확인

### 3. Target Group 상태
- EC2 콘솔 → Target Groups → ci-cd-demo-blue-tg
- **Health status**: healthy

## 다음 단계: Phase 3 (Blue/Green 배포)

서비스 생성 후 ECS 콘솔에서 Blue/Green 배포 전략으로 변경:

1. ECS 콘솔 → 서비스 → 배포 탭 → 편집
2. 배포 전략: **블루/그린** 선택
3. 로드 밸런서 역할: **ecsInfrastructureRoleForLoadBalancers** 선택
4. 그린 대상 그룹: **ci-cd-demo-green-tg** 선택

자세한 내용은 `phase3-blue-green-README.md` 참조
