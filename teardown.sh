#!/usr/bin/env bash
# Destroys the parameters, then empties and deletes the state bucket. Run with: ./teardown.sh
set -u
cd "$(dirname "$0")"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
B="clippy-tfstate-$ACCOUNT"
if [ -d terraform/.terraform ]; then
  echo "terraform destroy (the state is still in the bucket, so Terraform knows what to delete)..."
  terraform -chdir=terraform destroy -auto-approve -input=false || true
fi
# parameters created by hand or left behind
for p in $(aws ssm get-parameters-by-path --path /clippy/staging --query 'Parameters[].Name' --output text 2>/dev/null); do aws ssm delete-parameter --name "$p" && echo "deleted $p"; done
if aws s3api head-bucket --bucket "$B" >/dev/null 2>&1; then
  echo "Emptying and deleting s3://$B (every version)..."
  python3 - "$B" <<'PY'
import json, subprocess, sys
b = sys.argv[1]
while True:
    out = subprocess.check_output(["aws", "s3api", "list-object-versions", "--bucket", b, "--max-items", "500", "--output", "json"])
    v = json.loads(out or "{}")
    objs = [{"Key": x["Key"], "VersionId": x["VersionId"]} for x in (v.get("Versions") or []) + (v.get("DeleteMarkers") or [])]
    if not objs:
        break
    subprocess.check_call(["aws", "s3api", "delete-objects", "--bucket", b, "--delete", json.dumps({"Objects": objs, "Quiet": True})], stdout=subprocess.DEVNULL)
PY
  aws s3api delete-bucket --bucket "$B" && echo "deleted the bucket"
fi
rm -rf terraform/.terraform terraform/terraform.tfstate terraform/terraform.tfstate.backup
echo "Now run ./verify-teardown.sh"
