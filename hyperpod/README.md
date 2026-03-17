# Amazon SageMaker HyperPodを使ったSlurmクラスタ

このサンプルではSlurmクラスタを利用する場合にAmazon SageMaker HyperPodを利用した環境を構築します。共有ストレージには [Amazon FSx for Lustre](https://aws.amazon.com/jp/fsx/lustre/) を利用します。Lustre では [S3のバケットとリンク](https://docs.aws.amazon.com/ja_jp/fsx/latest/LustreGuide/create-dra-linked-data-repo.html)しいます。

## 構築されるアーキテクチャ

![Architecture](/hyperpod/docs/architecture.png)

## 目次

1. [デプロイについて](/hyperpod/docs/DEPLOYMENT.md)
1. [後片付け](/hyperpod/docs/CLEANUP.md)
