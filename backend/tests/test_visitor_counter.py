import importlib
import json
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch


BACKEND_SRC = Path(__file__).resolve().parents[1] / "src"
sys.path.insert(0, str(BACKEND_SRC))


def load_visitor_module():
    """Load the visitor module with a configured test table."""

    with patch.dict(
        "os.environ",
        {"VISITOR_TABLE_NAME": "test-visitor-table"}
    ):
        if "visitor_counter.app" in sys.modules:
            del sys.modules["visitor_counter.app"]

        return importlib.import_module("visitor_counter.app")


def test_visitor_counter_increments_count():
    """Verify that the visitor counter performs an atomic increment."""

    app = load_visitor_module()

    mock_table = MagicMock()
    mock_table.update_item.return_value = {
        "Attributes": {
            "count": 42
        }
    }

    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    with patch.object(
        app,
        "get_dynamodb_resource",
        return_value=mock_dynamodb
    ):
        response = app.lambda_handler({}, None)

    assert response["statusCode"] == 200
    assert response["headers"]["Content-Type"] == "application/json"

    body = json.loads(response["body"])

    assert body == {
        "count": 42
    }

    mock_dynamodb.Table.assert_called_once_with(
        "test-visitor-table"
    )

    mock_table.update_item.assert_called_once_with(
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


def test_visitor_counter_handles_dynamodb_failure():
    """Verify that DynamoDB failures return a controlled API response."""

    app = load_visitor_module()

    mock_table = MagicMock()
    mock_table.update_item.side_effect = Exception(
        "DynamoDB unavailable"
    )

    mock_dynamodb = MagicMock()
    mock_dynamodb.Table.return_value = mock_table

    with patch.object(
        app,
        "get_dynamodb_resource",
        return_value=mock_dynamodb
    ):
        response = app.lambda_handler({}, None)

    assert response["statusCode"] == 500
    assert response["headers"]["Content-Type"] == "application/json"

    body = json.loads(response["body"])

    assert body == {
        "error": "Unable to update visitor count."
    }