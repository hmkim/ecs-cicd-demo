# Phase 2: GitHub Actions CI/CD 파이프라인 

### 1. GitHub Actions 워크플로우
- `.github/workflows/ci-cd.yml` - CI/CD 파이프라인 정의

### 2. ECS Task Definition
- `task-definition.json` - 컨테이너 실행 설정

## 파이프라인 동작 과정

### 1. 트리거
- `main` 브랜치에 push 또는 PR 생성 시 자동 실행

### 2. 빌드 단계
1. 코드 체크아웃
2. AWS 인증 설정
3. ECR 로그인
4. Docker 이미지 빌드 및 푸시 (Git SHA 기반 태그)

### 3. 배포 단계
1. 현재 Task Definition 다운로드
2. 새 이미지로 Task Definition 업데이트
3. ECS 서비스에 새 Task Definition 배포
4. 서비스 안정성 대기

## 설정 필요사항

### Task Definition 수정
`task-definition.json`에서 `ACCOUNT_ID`를 실제 AWS 계정 ID로 교체:

**Account ID 확인 방법:**
- **AWS CLI**: `aws sts get-caller-identity --query Account --output text`
- **ECR URI에서 추출**: ECR URI 앞 12자리 숫자
- **CloudFormation 출력**: Role ARN에서 `arn:aws:iam::123456789012:role/...` 부분
 
## 다음 단계
- `bash phase2-1-deploy.sh` 