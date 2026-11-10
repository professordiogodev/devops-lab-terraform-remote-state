#!/usr/bin/env python3
import json, os, re, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)
ACCOUNT = sys.argv[1]
B = "clippy-tfstate-" + ACCOUNT
passed = failed = 0


def check(desc, ok, hint=""):
    global passed, failed
    if ok:
        passed += 1; print("PASS  " + desc)
    else:
        failed += 1; print("FAIL  " + desc + (("   -> " + hint) if hint else ""))


def aws(*a):
    try:
        return json.loads(subprocess.check_output(("aws",) + a + ("--output", "json"), stderr=subprocess.DEVNULL, timeout=60) or "null")
    except Exception:
        return None


def sh(c):
    r = subprocess.run(c, shell=True, capture_output=True, text=True)
    return r.returncode, r.stdout


print("== Your code ==")
tf = sh("cat terraform/*.tf")[1]
check("terraform fmt -check is clean", sh("terraform -chdir=terraform fmt -check")[0] == 0, "terraform -chdir=terraform fmt")
bk = re.search(r'backend\s+"s3"\s*\{(.*?)\n\s*\}', tf, re.S)
body = bk.group(1) if bk else ""
check("a backend \"s3\" block exists", bool(bk))
check("the backend uses the bucket %s" % B, ('"%s"' % B) in body)
check("the backend uses native locking (use_lockfile = true), not DynamoDB", re.search(r"use_lockfile\s*=\s*true", body) is not None and "dynamodb_table" not in body)
check("the backend has encrypt = true and a key", re.search(r"encrypt\s*=\s*true", body) is not None and re.search(r'key\s*=\s*"[^"]+"', body) is not None)
tracked = sh("git ls-files")[1].split("\n")
check("no state file, .terraform/ or tfvars committed", not [f for f in tracked if re.search(r"\.tfstate|(^|/)\.terraform/|\.tfvars$", f)])
check("no AWS keys in the repository", sh("git grep -lE 'AKIA[0-9A-Z]{16}' -- . ':!.lab' ':!verify.sh'")[1].strip() == "")

print("== The state bucket ==")
check("the bucket %s exists" % B, sh("aws s3api head-bucket --bucket %s" % B)[0] == 0, "create it with the CLI (Part 1)")
check("versioning is Enabled", (aws("s3api", "get-bucket-versioning", "--bucket", B) or {}).get("Status") == "Enabled")
enc = ((aws("s3api", "get-bucket-encryption", "--bucket", B) or {}).get("ServerSideEncryptionConfiguration", {}).get("Rules") or [{}])[0]
check("default encryption is on", bool(enc.get("ApplyServerSideEncryptionByDefault")))
c = (aws("s3api", "get-public-access-block", "--bucket", B) or {}).get("PublicAccessBlockConfiguration", {})
check("all four public access block options are on", len(c) == 4 and all(c.values()))
keym = re.search(r'key\s*=\s*"([^"]+)"', body)
key = keym.group(1) if keym else ""
vers = (aws("s3api", "list-object-versions", "--bucket", B, "--prefix", key) or {}).get("Versions", []) if key else []
vers = [v for v in vers if v["Key"] == key]
check("the state object %s exists in the bucket" % (key or "?"), len(vers) >= 1)
check("the state has at least 3 versions (initial migration, the bad apply, your rollback)", len(vers) >= 3, "found %d" % len(vers))
locks = [v for v in ((aws("s3api", "list-objects-v2", "--bucket", B, "--prefix", key + ".tflock") or {}).get("Contents") or [])] if key else []
check("no stale lock is left (%s.tflock)" % key, not locks, "terraform force-unlock <id>, only if nobody else is applying")

print("== Terraform and the real world ==")
check("no local state file: terraform/terraform.tfstate is absent or empty",
      not os.path.exists("terraform/terraform.tfstate") or os.path.getsize("terraform/terraform.tfstate") < 200 or '"resources": []' in open("terraform/terraform.tfstate").read())
rc, out = sh("terraform -chdir=terraform state list")
check("the remote state tracks the three parameters", rc == 0 and out.count("aws_ssm_parameter.clippy") == 3)
want = {"max_url_length": "2048", "code_length": "6", "cache_ttl": "300"}
got = {}
for k in want:
    p = aws("ssm", "get-parameter", "--name", "/clippy/staging/" + k)
    got[k] = (p or {}).get("Parameter", {}).get("Value")
check("the three real parameters hold the values in the code (the bad apply is undone)", got == want, "found %s" % got)
rc, out = sh("terraform -chdir=terraform plan -detailed-exitcode -input=false -no-color")
check("terraform plan finds nothing to change", rc == 0, "plan exit code %d" % rc)

print()
print(("ALL CHECKS PASSED (%d/%d)" % (passed, passed)) if failed == 0 else ("%d check(s) failed, %d passed" % (failed, passed)))
sys.exit(1 if failed else 0)
