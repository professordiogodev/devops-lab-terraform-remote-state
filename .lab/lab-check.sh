#!/usr/bin/env bash
rc=0
grep -q 'backend "s3"' terraform/*.tf && grep -q 'use_lockfile' terraform/*.tf && echo "- ✅ the S3 backend with use_lockfile is in the code" || { echo "- ❌ no backend \"s3\" with use_lockfile in terraform/"; rc=1; }
if git ls-files | grep -qE '\.tfstate|\.terraform/|\.tfvars$'; then echo "- ❌ state, .terraform/ or tfvars is committed"; rc=1; else echo "- ✅ no state or .terraform/ committed"; fi
grep -rEq 'AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude=tfcheck.py && { echo "- ❌ an AWS access key is committed"; rc=1; } || echo "- ✅ no AWS access key committed"
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
