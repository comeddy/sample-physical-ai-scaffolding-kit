# 배포 가이드

이 샘플은 CDK를 사용하여 AWS 리소스를 구축합니다. CDK로 리소스를 배포하려면 충분한 권한을 가진 AWS 자격 증명이 필요합니다.

## 1. 환경 요구사항

다음 환경에서 동작을 확인하였습니다.

- Node.js v22.18.0
- npm 10.9.3
- aws-cli 2.32.21
- Python 3.14(Lambda)
- Docker 25.0.8

## 2. 배포

CDK 배포 시 AWS 자격 증명과 리전을 다음 환경 변수로 지정해 주세요. 이 샘플은 us-east-1, us-west-2에서 동작 확인을 완료하였습니다. `AWS_DEFAULT_REGION`에는 실제 사용할 리전을 지정합니다.

```bash
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=us-east-1
```

### 2.1. CDK 설정

CDK가 설치되어 있지 않은 경우 [AWS CDK 시작하기](https://docs.aws.amazon.com/ja_jp/cdk/v2/guide/getting-started.html)를 참고하여 CDK를 설치해 주세요.

### 2.2. 샘플 다운로드

GitHub에서 샘플 코드를 clone합니다.

```bash
git clone https://github.com/aws-samples/sample-physical-ai-scaffolding-kit.git
cd sample-physical-ai-scaffolding-kit/hyperpod
```

### 2.3. 관련 node module 설치

이 CDK 스택에 필요한 라이브러리를 설치합니다.

```bash
npm install
```

### 2.4. CDK Bootstrap

CDK 배포에 필요한 환경을 준비합니다. 동일 리전에서 이미 한 번이라도 실행한 적이 있다면 다시 실행할 필요가 없습니다.

```bash
cdk bootstrap
```

### 2.5. 환경 설정

CDK로 배포되는 아키텍처에 대해 몇 가지 설정을 할 수 있습니다. 설정 파일은 [hyperpod/cdk.json](/hyperpod/cdk.json)에 있으며, 아래 부분이 설정 내용입니다.
초기 설정에는 worker group 설정이 포함되어 있지 않습니다. worker group에는 GPU를 가진 인스턴스를 지정하는 경우가 많기 때문에, 첫 번째 배포에서는 설정하지 않고 배포하여 인스턴스 할당이 불가능한 경우 전체가 실패하는 것을 방지할 수 있습니다. 이후 단계에서 worker group 배포를 진행합니다.

변경이 필요한 경우 `vim cdk.json`을 입력하여 커맨드라인 에디터로 수정해 주세요.

```json
"config": {
  "StackName": "PASK",  // CloudFormation의 Stack 이름을 변경하려면 수정해 주세요
  "Cluster": {
    "Name": "pask-cluster",  // Amazon SageMaker HyperPod의 클러스터 이름
    "ControllerGroup": {
      "Name": "controller-group",
      "Count": 1,
      "InstanceType": "ml.c5.large"
    },
    "LoginGroup": {
      "Name": "login-group",
      "Count": 1,
      "InstanceType": "ml.c5.large"
    },
    "WorkerGroup": []
  },
  "ClusterVPC": {
    "SubnetAZ": "",  // 사전에 특정 AZ를 지정하려면 입력
    "UseFlowLog": false  // VPC Flow logs를 활성화하려면 true로 설정
  },
  "Lustre": {
    "S3Prefix": "",  // Lustre 연결 대상 S3 버킷의 경로를 지정하려면 입력
    "FileSystemPath": "/s3link"  // 노드상의 경로는 `/fsx/여기서 지정한 값`이 됩니다
  }
}
```

#### 2.5.1. 클러스터 AZ 지정에 대해

기본적으로 g5, g6, g6e, g7e를 사용할 수 있는 AZ가 자동으로 선택됩니다.

[AZ 선택용 커스텀 리소스](/hyperpod/lib/lambda/custom-resources/subnet-selector/index.py)

그 외 특정 인스턴스 타입을 사용하는 경우에는, 아래 명령어로 확인한 AZ를 cdk.json의 ClusterVPC.SubnetAZ에 지정해 주세요.

```bash
aws ec2 describe-instance-type-offerings --location-type availability-zone --filters Name=instance-type,Values=p4d.24xlarge
```

### 2.6. 스택 배포

다음 명령어를 실행하여 환경을 구축합니다. 도중에 권한 확인이 있으므로 `y`를 입력하여 진행합니다. 이 명령어로 모든 환경을 한꺼번에 생성하기 때문에 완료까지 수십 분이 소요됩니다.

```sh
cdk deploy
```

배포가 성공하면 다음과 같은 출력을 확인할 수 있습니다. 이 출력 결과는 AWS 매니지먼트 콘솔에서 CloudFormation을 열면 `PASK`라는 스택이 있으며, 스택의 `Outputs` 탭에서 확인할 수 있습니다.

```bash
Outputs:
PASK.BucketDataBucketName = 데이터를 저장하는 S3 버킷 이름
PASK.ClusterAZNameParameterStore = 클러스터가 배포된 AZ 이름이 저장된 파라미터 스토어 이름
PASK.ClusterClusterAvailabilityZone = 클러스터가 배포된 AZ 이름
PASK.HyperPodClusterExecutionRoleARN = 클러스터 노드의 Role ARN
PASK.HyperPodClusterId = 클러스터 ID
PASK.HyperPodClusterSecurityGroup = 클러스터에서 사용되는 보안 그룹
PASK.HyperPodClusterSubnet = 클러스터가 배포된 서브넷 ID
PASK.HyperPodLifeCycleScriptBucketName = 라이프사이클 스크립트 저장용 S3 버킷
PASK.HyperPodLoginGroupName = 클러스터의 로그인 그룹 이름
PASK.Region = 리소스가 배포된 리전
```

클러스터에서 이 정보를 확인하려면 다음 명령어로 조회할 수 있습니다. (리전과 Stack 이름은 실제 사용한 값을 지정해 주세요)

```bash
export AWS_DEFAULT_REGION=us-east-1
aws cloudformation describe-stacks --stack-name PASK --query "Stacks[0].Outputs"
```

이것으로 필요한 리소스가 모두 준비되었습니다.

### 2.7. 클러스터 초기 설정

배포를 통해 HyperPod에 클러스터가 준비되었습니다. 이 단계에서는 클러스터에 SSH 접속하는 방법을 설명합니다.

먼저 [SSH 설정 스크립트](https://docs.aws.amazon.com/ja_jp/sagemaker/latest/dg/sagemaker-hyperpod-run-jobs-slurm-access-nodes.html)를 사용하여 로컬 PC에서 ssh 명령어로 접속할 수 있도록 설정합니다.

```bash
wget https://raw.githubusercontent.com/awslabs/awsome-distributed-training/refs/heads/main/1.architectures/5.sagemaker-hyperpod/easy-ssh.sh -O easy-ssh.sh
chmod +x easy-ssh.sh
```

**주의** `easy-ssh.sh`를 실행하려면 AWS 자격 증명을 지정해야 합니다.

실행 도중 `~/.ssh/config`에 추가할지, SSH 키를 생성할지 묻는 경우 `yes`로 답하면 다음번 로그인이 간편해집니다.

`easy-ssh.sh`는 인자로 `PASK.HyperPodLoginGroupName 값`과 `PASK.HyperPodClusterId 값`을 지정합니다. 기본 설정으로 배포한 경우 명령어는 다음과 같습니다.

```bash
./easy-ssh.sh -c login-group pask-cluster
```

SSH 접속에 성공하면 다음과 같은 출력이 표시됩니다.

```bash
Now you can run:

$ ssh pask-cluster

Starting session with SessionId: xxxxxxxx
#
```

이 상태는 login 노드에 root로 SSH 접속한 상태이므로, `exit`로 한 번 빠져나와 주세요.

빠져나온 후, 실행 중에 표시된 `ssh pask-cluster` 명령어로 SSH 접속합니다.

**주의** `easy-ssh.sh`로 `~/.ssh/config`에 추가되는 SSH 설정은 다음과 같이 ProxyCommand를 활용하여 [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager.html)를 통해 SSH 접속합니다. 따라서 **SSH 접속 시에는 AWS 자격 증명을 지정해야 합니다**. 주의해 주세요.

```bash
Host pask-cluster
    User ubuntu
    ProxyCommand sh -c "aws ssm start-session --target sagemaker-cluster:xxxxxxx_controller-group-i-xxxxxxxx --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

Session Manager를 사용한 세션은 아무 조작이 없으면 20분(기본값) 후 세션이 종료됩니다. 타임아웃 시간을 늘리고 싶은 경우 [AWS Systems Manager 문서](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-preferences-timeout.html)를 참고하여 설정을 변경해 주세요.

정상적으로 SSH 접속이 완료되면 다음과 같이 login 노드에 ubuntu 사용자로 접속할 수 있습니다.

```bash

~~생략~~

You're on the login
Controller Node IP: 10.1.xxx.xxx
Login Node IP: 10.1.xxx.xxx
Instance Type: ml.c5.large
ubuntu@ip-10-1-155-217:~$
```

Lustre 스토리지에 연결된 S3 버킷 디렉토리의 권한을 ubuntu 사용자도 쓸 수 있도록 변경합니다.

```bash
sudo chmod -R 777 /fsx/s3link
```

테스트로 파일을 작성하여 S3에 반영되는지 확인합니다.

```bash
touch /fsx/s3link/test.txt
```

[매니지먼트 콘솔](https://console.aws.amazon.com/s3/buckets)을 열고, `pask-bucketdata`로 시작하는 버킷을 선택하여 방금 생성한 파일이 존재하는지 확인해 주세요.

확인이 완료되면 login 노드에서 `exit`로 빠져나옵니다.

이후 작업은 로컬 PC 터미널에서 진행합니다.

### 2.8. worker group 추가

worker group을 추가하려면 cdk.json을 편집하고 다시 배포해야 합니다.
추가 worker group을 준비하려면 아래 절차를 따라 주세요.

#### 인스턴스 기동 수 제한 상향 요청 및 인스턴스 확보

사용하려는 인스턴스의 상한 조정 요청이 사전에 필요할 수 있습니다. 실제 사용할 인스턴스의 상한이 필요한 수로 설정되어 있는지 확인하고, 부족한 경우 인스턴스 수의 상한 조정을 요청해 주세요. **인스턴스 수나 종류에 따라 승인까지 시간이 걸릴 수** 있습니다.

제한 요청은 다음 순서로 진행합니다. **반드시 사용할 AWS 계정으로 로그인되어 있는지 확인해 주세요.**

1. <https://console.aws.amazon.com/servicequotas/>에 접속
1. 왼쪽 메뉴에서 `AWS services`를 선택
1. `Amazon SageMaker`를 검색하여 선택
1. `for cluster usage`를 검색란에 입력하고 검색 결과에 표시되는 사용하려는 인스턴스 타입을 선택합니다
1. `Request increase at account level` 버튼을 선택
1. `Increase quota value`에 값을 입력하고 `Request`를 클릭하면 반영됩니다

**주의** 이것은 상한 조정 요청이며, 해당 수가 반드시 확보되는 것은 아닙니다.

worker group에서 사용할 인스턴스를 확보할 수 없는 경우 배포에 실패합니다. 특히 GPU를 사용하는 인스턴스 타입의 경우, [Amazon SageMaker HyperPod flexible training plans](https://aws.amazon.com/jp/blogs/news/meet-your-training-timelines-and-budgets-with-new-amazon-sagemaker-hyperpod-flexible-training-plans/)를 활용하여 원하는 인스턴스를 확보해야 합니다. 확보 방법은 [Amazon SageMaker HyperPod flexible training plans](https://aws.amazon.com/jp/blogs/aws/meet-your-training-timelines-and-budgets-with-new-amazon-sagemaker-hyperpod-flexible-training-plans/)에 기재된 절차를 참고해 주세요.

**주의** Training plans에서는 실수로 구매한 경우 취소가 불가능합니다. Target이나 Instance Type 등에 오류가 없는지 충분히 주의해 주세요.

**Amazon SageMaker HyperPod flexible training plans**를 사용하는 경우, 상한 조정 페이지에서 `reserved capacity across training plans per Region`을 검색하고 사용할 인스턴스가 해당하는 경우 함께 상한 조정을 진행해 주세요.

### 2.9. CDK 배포로 worker group 생성

`cdk.json`에 다음과 같이 worker group 설정을 추가합니다. 실제 사용할 인스턴스 타입을 지정해 주세요. 또한, 여러 worker group을 추가하려면 복수로 추가해 주세요.

```json
"Cluster": {
  "Name": "pask-cluster",
  "ControllerGroup": {
    "Name": "controller-group",
    "Count": 1,
    "InstanceType": "ml.c5.large"
  },
  "LoginGroup": {
    "Name": "login-group",
    "Count": 1,
    "InstanceType": "ml.c5.large"
  },
  "WorkerGroup": [
    {
      "Name": "worker-group-1",
      "Count": 1,
      "InstanceType": "ml.g6e.2xlarge"
    }
  ]
},
```

cdk.json 편집이 완료되면 다음 명령어로 다시 배포합니다.

```bash
cdk deploy
```

배포가 성공하면 worker 노드를 사용할 수 있게 됩니다.

배포가 실패하고 다음과 같은 에러가 표시되는 경우, 인스턴스를 확보할 수 없었다는 의미입니다. 잠시 후 다시 배포하거나, 인스턴스를 확보한 후 실행해 주세요.

```bash
❌  PASK failed: ToolkitError: The stack named PASK failed to deploy: UPDATE_ROLLBACK_COMPLETE: Resource handler returned message: "Resource of type 'AWS::SageMaker::Cluster' with identifier 'Operation [UPDATE] on [arn:aws:sagemaker:us-east-1:0000000000:cluster/xxxxxxx] failed with status [InService] and error [We currently do not have sufficient capacity to launch new ml.g6e.2xlarge instances. Please try again.]' did not stabilize." (RequestToken: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx, HandlerErrorCode: NotStabilized)
```

---

이상으로 Amazon SageMaker HyperPod의 기본적인 환경 준비가 완료되었습니다.
생성된 HyperPod 클러스터를 매니지먼트 콘솔에서 확인하려면 [https://console.aws.amazon.com/sagemaker/home#/cluster-management](https://console.aws.amazon.com/sagemaker/home#/cluster-management)에 접속해 주세요. (표시되지 않는 경우 배포한 리전을 선택해 주세요)

HyperPod의 노드는 공통 Lustre 스토리지를 `/fsx`에 마운트하고 있습니다. 기본 사용자 ubuntu의 홈 디렉토리는 Lustre 상의 `/fsx/ubuntu`로 설정됩니다. Lustre 상의 `/fsx/s3link`는 `PASK.BucketDataBucketName`에 표시된 [S3 버킷과 연결](https://docs.aws.amazon.com/ja_jp/fsx/latest/LustreGuide/create-dra-linked-data-repo.html)되어 있으므로, 대량의 데이터는 이 S3 버킷에 업로드하여 클러스터에서 사용하면 각 노드가 Lustre를 통해 S3 데이터에 접근할 수 있어 데이터 활용이 편리합니다.
