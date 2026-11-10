#!/usr/bin/env bash
# Proves the lab left nothing in AWS. Run with: ./verify-teardown.sh
set -u
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
echo "Checking account $ACCOUNT"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
check "no parameters under /clippy/staging" bash -c "[ -z \"\$(aws ssm get-parameters-by-path --path /clippy/staging --query 'Parameters[].Name' --output text)\" ]"
check "the state bucket clippy-tfstate-$ACCOUNT is gone" bash -c "! aws s3api head-bucket --bucket clippy-tfstate-$ACCOUNT"
check "no .terraform/ directory or state file left in terraform/" bash -c "! ls terraform/.terraform terraform/terraform.tfstate >/dev/null 2>&1"
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) in account $ACCOUNT"; else echo "NOT CLEAN: $failn leftover(s). Remove them and run this again."; fi
exit "$failn"
