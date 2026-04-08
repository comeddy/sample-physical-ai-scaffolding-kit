# Amazon SageMaker HyperPod를 활용한 Slurm 클러스터 구축

이 샘플에서는 Slurm 클러스터로서 Amazon SageMaker HyperPod를 활용한 환경을 구축하는 방법을 소개합니다.

## 구축되는 아키텍처

노드의 공유 스토리지로 [Amazon FSx for Lustre](https://aws.amazon.com/jp/fsx/lustre/)를 사용합니다. Lustre는 [S3 버킷과 연결](https://docs.aws.amazon.com/ja_jp/fsx/latest/LustreGuide/create-dra-linked-data-repo.html)되어 있어, 축적된 데이터를 손쉽게 활용할 수 있습니다.

![Architecture](/hyperpod/docs/architecture.png)

## 목차

1. [배포 가이드](/hyperpod/docs/DEPLOYMENT.md)
1. [정리(리소스 삭제)](/hyperpod/docs/CLEANUP.md)
