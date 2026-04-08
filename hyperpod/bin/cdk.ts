#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { PASKStack } from '../lib/pask-stack';
import { Configuration } from '../lib/types/configurations';
import { AwsSolutionsChecks } from 'cdk-nag';
import { Aspects } from 'aws-cdk-lib';

const app = new cdk.App();
const config = app.node.tryGetContext('config') as Configuration;

// Nag 검사를 활성화하려면 아래 주석을 해제하세요
// Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));

new PASKStack(app, config.StackName, {
  config,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION,
  },
});
