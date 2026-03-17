import * as cdk from 'aws-cdk-lib';
import { aws_fsx, aws_ec2, aws_s3, aws_logs, aws_iam, aws_lambda } from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { Configuration } from '../types/configurations';
import * as path from 'path';
import { PolicyDocument } from 'aws-cdk-lib/aws-iam';

export interface LustreProps {
  config: Configuration;
  dataBucket: aws_s3.IBucket;
  vpc: aws_ec2.IVpc;
  privateSubnet: aws_ec2.PrivateSubnet;
  lsfSecurityGroup: aws_ec2.ISecurityGroup;
}

export class Lustre extends Construct {
  public readonly fs: aws_fsx.LustreFileSystem;
  constructor(scope: Construct, id: string, props: LustreProps) {
    super(scope, id);

    const lustreConfiguration = {
      deploymentType: aws_fsx.LustreDeploymentType.PERSISTENT_2,
      perUnitStorageThroughput: 250,
      dataCompressionType: aws_fsx.LustreDataCompressionType.LZ4,
    };

    this.fs = new aws_fsx.LustreFileSystem(this, 'FsxLustreFileSystem', {
      vpc: props.vpc,
      vpcSubnet: props.privateSubnet,
      storageCapacityGiB: 1200,
      securityGroup: props.lsfSecurityGroup,
      storageType: aws_fsx.StorageType.SSD,
      fileSystemTypeVersion: aws_fsx.FileSystemTypeVersion.V_2_15,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // TODO: This should be retain to save data
      lustreConfiguration,
    });

    props.dataBucket.addToResourcePolicy(
      new aws_iam.PolicyStatement({
        effect: aws_iam.Effect.ALLOW,
        principals: [new aws_iam.ServicePrincipal('fsx.amazonaws.com')],
        actions: [
          's3:AbortMultipartUpload',
          's3:DeleteObject',
          's3:Get*',
          's3:List*',
          's3:PutBucketNotification',
          's3:PutObject',
        ],
        resources: [props.dataBucket.bucketArn, `${props.dataBucket.bucketArn}/*`],
        conditions: {
          StringEquals: {
            'aws:SourceAccount': cdk.Stack.of(this).account,
          },
        },
      }),
    );

    // Custom resource to update s3 link to Lustre
    // https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-linked-dra.html
    const lustreLinkUpdateLogGroup = new aws_logs.LogGroup(this, 'LustreLinkUpdateLogGroup', {
      retention: aws_logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const lustreLinkUpdateFunctionRole = new aws_iam.Role(this, 'LustreLinkUpdateFunctionRole', {
      assumedBy: new aws_iam.ServicePrincipal('lambda.amazonaws.com'),
      inlinePolicies: {
        AllowUpdateLustre: new PolicyDocument({
          statements: [
            new aws_iam.PolicyStatement({
              actions: [
                'fsx:CreateDataRepositoryAssociation',
                'fsx:DeleteDataRepositoryAssociation',
                'fsx:DescribeDataRepositoryAssociations',
                'fsx:UpdateDataRepositoryAssociation',
              ],
              resources: [
                `arn:aws:fsx:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:file-system/${this.fs.fileSystemId}`,
                `arn:aws:fsx:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:association/${this.fs.fileSystemId}/*`,
              ],
            }),
            new aws_iam.PolicyStatement({
              actions: ['iam:CreateServiceLinkedRole', 'iam:AttachRolePolicy', 'iam:PutRolePolicy'],
              resources: [
                'arn:aws:iam::*:role/aws-service-role/s3.data-source.lustre.fsx.amazonaws.com/*',
              ],
            }),
          ],
        }),
      },
    });
    lustreLinkUpdateLogGroup.grantWrite(lustreLinkUpdateFunctionRole);
    props.dataBucket.grantReadWrite(lustreLinkUpdateFunctionRole);

    const lustreLinkUpdateFunction = new aws_lambda.Function(this, 'LustreLinkUpdateFunction', {
      runtime: aws_lambda.Runtime.PYTHON_3_14,
      memorySize: 128,
      handler: 'index.handler',
      role: lustreLinkUpdateFunctionRole,
      code: aws_lambda.Code.fromAsset(
        path.join(__dirname, '../lambda/custom-resources/lustre-link-update'),
      ),
      timeout: cdk.Duration.minutes(1),
      logGroup: lustreLinkUpdateLogGroup,
    });
    const lustreLinkUpdateResource = new cdk.CustomResource(this, 'LustreLinkUpdateResource', {
      serviceToken: lustreLinkUpdateFunction.functionArn,
      resourceType: 'Custom::UpdateLustreS3Link',
      properties: {
        FileSystemId: this.fs.fileSystemId,
        FileSystemPath: props.config.Lustre.FileSystemPath,
        S3BucketName: props.dataBucket.bucketName,
        S3BucketPrefix: props.config.Lustre.S3Prefix,
      },
    });
    lustreLinkUpdateResource.node.addDependency(this.fs);
  }
}
