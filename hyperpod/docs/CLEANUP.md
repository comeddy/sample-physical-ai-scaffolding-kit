# 정리(리소스 삭제)

환경이 더 이상 필요하지 않은 경우, 잊지 말고 삭제하여 불필요한 비용이 발생하지 않도록 합니다.

## 전체 리소스 삭제

다음 명령어를 실행하여 모든 스택을 삭제합니다.

```bash
cdk destroy
```

Cloud Shell 세션이 종료된 경우에는 소스를 다시 업로드해야 하므로, CloudFormation 콘솔에서 직접 삭제합니다.

[https://console.aws.amazon.com/cloudformation/home#/stacks](https://console.aws.amazon.com/cloudformation/home#/stacks)

`PASK` 스택을 선택하고 삭제해 주세요.

다음 리소스는 삭제되지 않고 남아 있으므로 수동으로 삭제해 주세요. 이미 SageMaker를 사용 중인 경우에는 사용 중인 리소스일 수 있으니 삭제 시 주의해 주세요.

- Amazon CloudWatch 로그 그룹
  - /aws/lambda/PASK-*
  - /aws/sagemaker/Clusters/pask-cluster/*
- S3 버킷
  - pask-*
