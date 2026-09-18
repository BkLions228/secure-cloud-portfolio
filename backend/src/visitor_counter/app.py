import json
import os

import boto3


TABLE_NAME = os.environ.get("VISITOR_TABLE_NAME")


def get_dynamodb_resource():
    """Create and return the DynamoDB resource."""

    return boto3.resource("dynamodb")


def lambda_handler(event, context):
    """Atomically increment and return the portfolio visitor count."""

    if not TABLE_NAME:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "error": "Visitor table is not configured."
            })
        }

    try:
        dynamodb = get_dynamodb_resource()
        table = dynamodb.Table(TABLE_NAME)

        response = table.update_item(
            Key={
                "counter_id": "portfolio"
            },
            UpdateExpression="ADD #count :increment",
            ExpressionAttributeNames={
                "#count": "count"
            },
            ExpressionAttributeValues={
                ":increment": 1
            },
            ReturnValues="UPDATED_NEW"
        )

        visitor_count = int(response["Attributes"]["count"])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "count": visitor_count
            })
        }

    except Exception:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "error": "Unable to update visitor count."
            })
        }