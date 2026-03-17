import boto3
import json
import logging
import traceback
import urllib.request

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# CloudFormation response constants
SUCCESS = "SUCCESS"
FAILED = "FAILED"


def send_cfn_response(
    event,
    context,
    response_status,
    response_data,
    physical_resource_id=None,
    no_echo=False,
    reason=None,
):
    """
    Send a response to CloudFormation regarding the success or failure of a custom resource deployment.
    """
    response_url = event["ResponseURL"]

    logger.info(f"CFN response URL: {response_url}")

    response_body = {
        "Status": response_status,
        "Reason": reason
        or f"See the details in CloudWatch Log Stream: {context.log_stream_name}",
        "PhysicalResourceId": physical_resource_id or context.log_stream_name,
        "StackId": event["StackId"],
        "RequestId": event["RequestId"],
        "LogicalResourceId": event["LogicalResourceId"],
        "NoEcho": no_echo,
        "Data": response_data,
    }

    json_response_body = json.dumps(response_body)
    logger.info(f"Response body: {json_response_body}")

    headers = {
        "Content-Type": "application/json",
        "Content-Length": str(len(json_response_body)),
    }

    try:
        req = urllib.request.Request(
            url=response_url,
            data=json_response_body.encode("utf-8"),
            headers=headers,
            method="PUT",
        )

        with urllib.request.urlopen(req) as response:
            logger.info(f"Status code: {response.getcode()}")
            logger.info(f"Status message: {response.msg}")

    except Exception as e:
        logger.error(f"Error sending CFN response: {str(e)}")
        logger.error(f"Response URL: {response_url}")
        logger.error(f"Response body: {json_response_body}")


def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    try:
        s3 = boto3.client("s3")

        request_type = event["RequestType"]
        if request_type == "Create" or request_type == "Update":
            # Get parameters from event
            props = event["ResourceProperties"]
            bucket_name = props["BucketName"]

            # Create provisioning parameters JSON
            worker_groups = []
            for group in props["WorkerGroup"]:
                worker_groups.append(
                    {
                        "instance_group_name": group["Name"],
                        "partition_name": group["InstanceType"],
                    }
                )
            provisioning_params = {
                "version": "1.0.0",
                "workload_manager": "slurm",
                "controller_group": props["ControllerGroupName"],
                "worker_groups": worker_groups,
                "login_group": props["LoginGroupName"],
                "fsx_dns_name": props["FsxDnsName"],
                "fsx_mountname": props["FsxMountName"],
            }

            # Upload to S3
            s3.put_object(
                Bucket=bucket_name,
                Key="provisioning_parameters.json",
                Body=json.dumps(provisioning_params, indent=2),
                ContentType="application/json",
            )

        send_cfn_response(event, context, SUCCESS, {"Message": "Finished successfully"})

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        logger.error(traceback.format_exc())
        send_cfn_response(event, context, FAILED, {"Error": str(e)})
