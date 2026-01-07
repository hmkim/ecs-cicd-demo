# Phase 3: ECS 네이티브 Blue/Green 배포 구성

## 개요

AWS ECS의 **네이티브 Blue/Green 배포** 기능을 사용합니다.
2025년 출시된 이 기능은 CodeDeploy 없이 ECS 자체에서 Blue/Green 배포를 지원합니다.

## 전제 조건

- ✅ Phase 1: 기본 인프라 완료 (ecsInfrastructureRoleForLoadBalancers 포함)
- ✅ Phase 2: GitHub Actions 파이프라인 완료  
- ✅ Phase 2-1: ECS 서비스 생성 완료

## Blue/Green 배포 설정 (콘솔)

### 1. ECS 콘솔에서 서비스 업데이트

1. **AWS 콘솔** → **ECS** → **클러스터** → **ci-cd-demo-cluster**
2. **서비스** 탭 → **ci-cd-demo-service** 선택
3. **배포** 탭 → **편집** 버튼 클릭

### 2. 배포 전략 설정

| 항목 | 값 |
|------|-----|
| 배포 전략 | **블루/그린** |
| Bake time | 5분 (권장) |

### 3. 로드 밸런싱 설정

| 항목 | 값 |
|------|-----|
| 컨테이너 | `app 8080:8080` |
| 로드 밸런서 | `ci-cd-demo-alb` |
| 리스너 | `HTTP:80` |
| 프로덕션 리스너 규칙 | `우선순위: default` |
| 블루 대상 그룹 | `ci-cd-demo-blue-tg` |
| 그린 대상 그룹 | `ci-cd-demo-green-tg` |
| **로드 밸런서 역할** | `ecsInfrastructureRoleForLoadBalancers` |

### 4. 업데이트 완료

**업데이트** 버튼 클릭하여 설정 저장

## ECS 네이티브 Blue/Green 동작 방식

### 배포 라이프사이클

```
1. RECONCILE_SERVICE    - 서비스 상태 확인
2. PRE_SCALE_UP        - 스케일업 전 훅 (선택)
3. SCALE_UP            - Green 환경 생성
4. POST_SCALE_UP       - 스케일업 후 훅 (선택)
5. TEST_TRAFFIC_SHIFT  - 테스트 트래픽 전환 (선택)
6. PRODUCTION_TRAFFIC_SHIFT - 프로덕션 트래픽 전환
7. BAKE_TIME           - 안정화 대기 시간
8. CLEAN_UP            - Blue 환경 정리
```

### 자동 롤백 조건
- 배포 실패 시
- 헬스체크 실패 시
- CloudWatch 알람 트리거 시
- 수동 중단 시

## CodeDeploy 방식과의 차이점

| 항목 | ECS 네이티브 | CodeDeploy |
|------|-------------|------------|
| 설정 위치 | ECS 서비스 내 | 별도 CodeDeploy 리소스 |
| IAM Role | ecsInfrastructureRoleForLoadBalancers | CodeDeploy Service Role |
| 라이프사이클 훅 | Lambda 함수 (선택) | AppSpec hooks |
| Canary/Linear | 지원 | 지원 |
| 관리 복잡도 | 낮음 | 높음 |

## 장점

- ✅ **단순한 구성**: CodeDeploy 리소스 불필요
- ✅ **통합 관리**: ECS 콘솔에서 모든 배포 관리
- ✅ **AWS 관리형 정책**: `AmazonECSInfrastructureRolePolicyForLoadBalancers` 사용
- ✅ **무중단 배포**: Blue/Green 방식으로 다운타임 없음
- ✅ **자동 롤백**: 문제 발생 시 즉시 복구

## 다음 단계

### 1. 배포 테스트
- 코드 변경 후 새 Task Definition 등록
- ECS 서비스 업데이트로 Blue/Green 배포 실행

### 2. 모니터링 설정
- CloudWatch 알람 설정
- 자동 롤백 조건 구성

### 3. CI/CD 파이프라인 연동
- GitHub Actions에서 ECS UpdateService API 호출
