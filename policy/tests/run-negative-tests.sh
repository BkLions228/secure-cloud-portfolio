#!/usr/bin/env bash

set -u

echo "=========================================="
echo "Policy-as-Code Negative Security Tests"
echo "=========================================="
echo

failures=0

echo "[TEST 1] Insecure Terraform S3 configuration"
echo "Expected: Checkov rejects the configuration."
echo

if checkov \
  -d policy/tests/fixtures/fail/terraform \
  --framework terraform \
  --compact \
  --check CKV_AWS_53,CKV_AWS_54,CKV_AWS_55,CKV_AWS_56
then
  echo
  echo "ERROR: Insecure Terraform configuration was accepted."
  failures=$((failures + 1))
else
  echo
  echo "PASS: Insecure Terraform configuration was correctly rejected."
fi

echo
echo "------------------------------------------"
echo

echo "[TEST 2] Insecure SAM API Gateway configuration"
echo "Expected: Checkov rejects an HTTP API without access logging."
echo

if checkov \
  -f policy/tests/fixtures/fail/cloudformation/insecure-api.yaml \
  --framework cloudformation \
  --compact \
  --check CKV_AWS_95
then
  echo
  echo "ERROR: Insecure SAM API configuration was accepted."
  failures=$((failures + 1))
else
  echo
  echo "PASS: Insecure SAM API configuration was correctly rejected."
fi

echo
echo "=========================================="

if [ "$failures" -ne 0 ]; then
  echo "NEGATIVE POLICY TESTS FAILED"
  echo "$failures insecure configuration(s) escaped policy enforcement."
  exit 1
fi

echo "ALL NEGATIVE POLICY TESTS PASSED"
echo "All intentionally insecure configurations were blocked."
