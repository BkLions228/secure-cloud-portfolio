import json


def lambda_handler(event, context):
    """Return the health status of the visitor analytics API."""

    response_body = {
        "status": "healthy"
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response_body)
    }