# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `terraform/` with your `.tf` files (no state, no `.terraform/`)

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste your `backend` block and the `aws s3api get-bucket-versioning` output of the state bucket. Why must the bucket have versioning and encryption and why must nobody else be able to read it?

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the error of the second `terraform apply` while the first held the lock. What was written in S3 to cause it (`.tflock`), and what do you do if the process holding the lock crashed (`terraform force-unlock`) and what could go wrong?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. Paste `aws s3api list-object-versions` for your state key. Which version would you restore after a bad apply and how did you do it? What did `terraform plan` say afterwards?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. The bad apply changed a tag. Terraform and the real parameter now disagree with an older state. Explain in your words what Terraform compares in a plan (config, state and real world).

**Your answer:**

<!-- replace this line with your answer -->

### Q5. Why can the state bucket not be created by the same Terraform that uses it as a backend? How did you solve the chicken and egg problem?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q7. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
