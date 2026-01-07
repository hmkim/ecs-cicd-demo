# Phase 1: 기본 인프라 구성  

## 생성된 리소스

### 1. 네트워킹
- **VPC**: 10.0.0.0/16 (ci-cd-demo-vpc)
- **Public Subnets**: 2개 Multi-AZ (ci-cd-demo-public-subnet-1/2)
- **Internet Gateway**: ci-cd-demo-igw
- **Route Table**: ci-cd-demo-public-rt
- **Security Groups**: 
  - ALB Security Group (ci-cd-demo-alb-sg): HTTP/HTTPS 허용
  - ECS Security Group (ci-cd-demo-ecs-sg): ALB에서 8080 포트 허용

### 2. 컨테이너 인프라
- **ECR Repository**: ci-cd-demo-app (이미지 스캔 활성화, 10개 이미지 보관)
- **ECS Cluster**: ci-cd-demo-cluster (Fargate/Fargate Spot, Container Insights 활성화)
- **Application Load Balancer**: ci-cd-demo-alb (인터넷 연결)

### 3. Blue/Green 배포 준비
- **Blue Target Group**: ci-cd-demo-blue-tg (포트 8080, /health 헬스체크)
- **Green Target Group**: ci-cd-demo-green-tg (포트 8080, /health 헬스체크)
- **ALB Listener**: HTTP 80포트, Blue Target Group으로 기본 라우팅

### 4. IAM 역할 및 사용자
- **ECS Task Execution Role**: ci-cd-demo-ecs-task-execution-role (ECR 접근)
- **ECS Task Role**: ci-cd-demo-ecs-task-role (애플리케이션 실행)
- **CodeDeploy Service Role**: ci-cd-demo-codedeploy-service-role (Blue/Green 배포)
- **GitHub Actions User**: ci-cd-demo-github-actions-user (CI/CD 파이프라인용)

### 5. 모니터링
- **CloudWatch Log Group**: /ecs/ci-cd-demo (7일 보관)
- **Container Insights**: ECS 클러스터 메트릭 수집

## 배포 방법

```bash
cd /Users/jikjeong/Develop/demo/ci-cd-demo/infrastructure
./phase1-deploy.sh
```
 
인프라 배포 완료 후 다음 정보들이 출력됩니다:

### GitHub Repository Secrets 설정용:
- **GitHubActionsAccessKeyId** → `AWS_ACCESS_KEY_ID`
- **GitHubActionsSecretAccessKey** → `AWS_SECRET_ACCESS_KEY`
- **ECRRepositoryURI** → `ECR_REPOSITORY_URI`
- **AWS Region** → `AWS_REGION` (ap-northeast-2)

### Phase 2에서 사용할 정보:
- **ECSClusterName** - ECS 클러스터 이름
- **ALBDNSName** - 로드밸런서 주소
- **BlueTargetGroupArn** / **GreenTargetGroupArn** - Blue/Green 배포용
- **VPCId**, **PublicSubnet1Id**, **PublicSubnet2Id** - 네트워크 정보
- **ECSSecurityGroupId** - 보안 그룹
- **ECSTaskExecutionRoleArn**, **ECSTaskRoleArn** - IAM 역할

이 정보들은 Phase 2 (GitHub Actions 파이프라인)에서 사용됩니다.
