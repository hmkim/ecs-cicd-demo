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
- **Load Balancer**: Blue Target Group에 연결
 
## 배포 전 필수 작업: 첫 번째 이미지 푸시 (이후에는 github action으로 push 함)

### 1. ECR 로그인
```bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com
```

### 2. 이미지 빌드 및 푸시

**ACCOUNT_ID를 실제 AWS 계정 ID로 교체하세요.**
**필요시, ecr에서 푸시명령 command 확인**
```bash
# 프로젝트 루트에서 실행
docker build --platform linux/amd64 -t ci-cd-demo-app .
# 아래 ACCOUNT_ID는 변경 필요
 
docker tag ci-cd-demo-app:latest {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/ci-cd-demo-app:latest
docker push {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/ci-cd-demo-app:latest
```

### 참고: 사용자 확인 "aws sts get-caller-identity"

## 배포 순서

1. **첫 번째 이미지 푸시** (위 명령어 실행)
2. **ECS 서비스 배포** (`./phase2-1-deploy.sh`)
3. **서비스 상태 확인** (AWS 콘솔에서 ECS 서비스 확인)
4. **ALB DNS로 애플리케이션 접근 테스트**

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
 

## 다음 단계

Phase 2-1 완료 후:
1. **GitHub에 코드 푸시** → GitHub Actions 자동 실행
2. **Phase 3: Blue/Green 배포** 구성
3. **Phase 4: 모니터링 및 롤백** 설정
