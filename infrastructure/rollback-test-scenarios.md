# 자동 롤백 테스트 시나리오

ECS Blue/Green 배포의 자동 롤백 기능을 테스트하기 위한 시나리오 모음입니다.

> ⚠️ **중요**: 롤백은 **배포 중**에만 발생합니다. 배포 완료 후 크래시는 롤백이 아닌 **태스크 재시작**으로 처리됩니다.

## 테스트 전 확인사항

- [ ] ECS 서비스가 Blue/Green 배포 전략으로 설정됨
- [ ] 현재 서비스가 정상 동작 중 (Blue 환경)
- [ ] ALB 헬스체크 설정: `/health` 엔드포인트

---

## 시나리오 1: 헬스체크 실패 (권장 테스트)

### 설명
애플리케이션은 정상 시작되지만 헬스체크에서 실패하는 케이스

### 헬스체크 설정 위치
`EC2 → 로드 밸런싱 → 대상 그룹 → ci-cd-demo-blue-tg → 상태 검사 탭`

### 코드 변경 (app.py)
```python
# 변경 전
@app.route('/health')
def health():
    return "OK", 200

# 변경 후
@app.route('/health')
def health():
    return "FAIL", 500
```

### 예상 결과
1. 이미지 빌드 ✅ 성공
2. ECR 푸시 ✅ 성공
3. Green 태스크 시작 ✅ 성공
4. ALB 헬스체크 ❌ 실패 (HTTP 500)
5. **자동 롤백** → Blue 환경 유지

### 롤백 소요 시간
약 2-5분 (헬스체크 간격 × 실패 임계값)

---

## 시나리오 2: 애플리케이션 시작 실패

### 설명
컨테이너는 시작되지만 애플리케이션 초기화 중 예외 발생

### 코드 변경 (app.py)
```python
# 파일 최상단에 추가
raise Exception("Intentional startup failure for rollback test")
```

### 예상 결과
1. 이미지 빌드 ✅ 성공
2. ECR 푸시 ✅ 성공
3. Green 태스크 시작 ❌ 실패 (컨테이너 크래시)
4. ECS 태스크 재시작 시도 (최대 재시도 후 실패)
5. **자동 롤백** → Blue 환경 유지

### 롤백 소요 시간
약 3-7분 (재시도 횟수에 따라)

---

## 시나리오 3: 포트 불일치

### 설명
애플리케이션이 Task Definition에 정의된 포트와 다른 포트에서 실행

### 코드 변경 (Dockerfile 또는 gunicorn 설정)
```dockerfile
# 잘못된 포트로 변경
CMD ["gunicorn", "--bind", "0.0.0.0:9999", "app:app"]
```

### 예상 결과
1. 이미지 빌드 ✅ 성공
2. Green 태스크 시작 ✅ 성공
3. ALB → 8080 포트 연결 ❌ 실패
4. 헬스체크 ❌ 실패 (Connection refused)
5. **자동 롤백** → Blue 환경 유지

---

## 시나리오 4: 의존성 연결 실패

### 설명
필수 외부 서비스(DB, Redis 등) 연결 실패 시 헬스체크 실패

### 코드 변경 (app.py)
```python
import socket

@app.route('/health')
def health():
    # 존재하지 않는 서비스 연결 시도
    try:
        sock = socket.create_connection(("nonexistent-db.local", 5432), timeout=5)
        sock.close()
        return "OK", 200
    except:
        return "Database connection failed", 503
```

### 예상 결과
1. Green 태스크 시작 ✅ 성공
2. 헬스체크 ❌ 실패 (503 응답)
3. **자동 롤백** → Blue 환경 유지

---

## 시나리오 5: CloudWatch 알람 기반 롤백

### 설명
애플리케이션 메트릭(에러율)이 임계값 초과 시 자동 롤백

### Step 1: CloudWatch 알람 생성

**콘솔 경로**:
```
CloudWatch → 알람 → 알람 생성
```

**설정값**:

| 항목 | 값 |
|------|-----|
| 지표 선택 | `ApplicationELB → Per AppELB Metrics → HTTPCode_ELB_5XX_Count` |
| 로드 밸런서 | `ci-cd-demo-alb` |
| 통계 | 합계 (Sum) |
| 기간 | 1분 |
| 조건 | 보다 큼 > **10** |
| 알람 이름 | `ci-cd-demo-5xx-alarm` |

> 💡 `HTTPCode_ELB_5XX_Count`는 ALB 전체 지표라서 Blue/Green 어디서든 에러 감지 가능

**CLI로 생성**:
```bash
# ALB ARN suffix 확인  
ALB_SUFFIX=$(aws elbv2 describe-load-balancers \
  --names ci-cd-demo-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text --region ap-northeast-2 | cut -d: -f6 | cut -d/ -f2-)

# 알람 생성 (ALB 전체 지표)
aws cloudwatch put-metric-alarm \
  --alarm-name ci-cd-demo-5xx-alarm \
  --metric-name HTTPCode_ELB_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=LoadBalancer,Value=$ALB_SUFFIX \
  --region ap-northeast-2
```

### Step 2: ECS 서비스에 알람 연결

**콘솔 경로**:
```
ECS → 클러스터 → ci-cd-demo-cluster → 서비스 → 배포 탭 → 편집
```

1. "배포 실패 감지" 섹션
2. "CloudWatch 알람 사용" 활성화
3. 알람 선택: `ci-cd-demo-5xx-alarm`
4. 업데이트

### Step 3: 테스트 코드 (app.py)

```python
import random

@app.route('/')
def home():
    # 50% 확률로 500 에러
    if random.random() < 0.5:
        return "Internal Server Error", 500
    return "Hello World", 200

@app.route('/health')
def health():
    return "OK", 200  # 헬스체크는 통과
```

### Step 4: 트래픽 발생

```bash
# 100회 요청으로 5xx 에러 유도
for i in {1..100}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://ALB_DNS_NAME/
  sleep 0.5
done
```

### 예상 결과
1. 새 버전 배포 완료 (Green)
2. 트래픽 전환
3. 50% 에러 발생 → 5xx 카운트 증가
4. CloudWatch 알람 트리거
5. **자동 롤백** → Blue 환경 복구

### 확인 방법

```bash
# 알람 상태 확인
aws cloudwatch describe-alarms \
  --alarm-names ci-cd-demo-5xx-alarm \
  --query 'MetricAlarms[0].StateValue' \
  --region ap-northeast-2
```

---

## 롤백 확인 방법

### ECS 콘솔
```
ECS → 클러스터 → ci-cd-demo-cluster → 서비스 → 배포 탭
```

### AWS CLI
```bash
# 배포 상태 확인
aws ecs describe-services \
  --cluster ci-cd-demo-cluster \
  --services ci-cd-demo-service \
  --query 'services[0].deployments' \
  --region ap-northeast-2

# 이벤트 로그 확인
aws ecs describe-services \
  --cluster ci-cd-demo-cluster \
  --services ci-cd-demo-service \
  --query 'services[0].events[:10]' \
  --region ap-northeast-2
```

### CloudWatch Logs
```
로그 그룹: /ecs/ci-cd-demo
```

---

## 테스트 후 복구

테스트 완료 후 원래 코드로 복구:

```bash
git checkout app.py
git push origin main
```

또는 이전 정상 이미지로 롤백:

```bash
aws ecs update-service \
  --cluster ci-cd-demo-cluster \
  --service ci-cd-demo-service \
  --task-definition ci-cd-demo-service:PREVIOUS_REVISION \
  --region ap-northeast-2
```
