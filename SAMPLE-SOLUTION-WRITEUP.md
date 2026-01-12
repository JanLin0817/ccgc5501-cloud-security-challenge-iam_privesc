## Solution:

To find the flag, I’ve taken the following steps:

a. I have reviewed the IAM Policy which shows the S3 bucket path, SQS queue service, and permissions. The policy allows public access to send messages to the queue and read messages from it. From the policy, I found the path:

```
arn:aws:sqs:us-east-1:092297851374:wiz-tbic-analytics-sqs-queue-ca7a1b2
```

b. To read messages stored in the queue, I’ve looked below references online to obtain the AWS CLI command syntax. The reference provides a generic syntax only so it needs to be modified.
- https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sqs/receive-message.html

   The command is: 
   ```
   aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws/092297851374/wiz-tbic-analytics-sqs-queue-ca7a1b2 --attribute-names All
   ```

c. The command output displayed the message content which contains the following URL: 
```
https://tbic-wiz-analytics-bucket-b44867f.s3.amazonaws.com/pAXCWLa6ql.html
```

d. I’ve opened the URL on a web browser and displays the flag. The flag is: 
   ```
   {wiz:you-are-at-the-front-of-the-queue}
   ```
---

## Reflection:

### What was your approach?

My approach started with reviewing the IAM policy. I noticed it allowed public access to send and read messages from the SQS queue. Using the queue path from the policy, I searched online for AWS CLI commands to interact with the queue. I used the receive-message command to read the messages stored in the queue, which led me to a URL. Finally, I opened the URL in a browser and found the flag.

### What was the biggest challenge?

The biggest challenge was understanding how to properly use the AWS CLI commands. The examples online showed only generic syntax, so I had to figure out how to modify the commands for this specific SQS queue.

### How did you overcome the challenges?

I carefully read the AWS CLI documentation to understand the required parameters. Then, I tested the commands step by step, making adjustments until the command successfully retrieved the messages from the queue.

### What led to the breakthrough?

The breakthrough happened when I received the message content from the queue, which contained the URL. It confirmed that the command was working correctly and gave me the next clue to find the flag.

### On the blue side, how can the learning be used to properly defend the important assets?

This learning shows the risks of giving public access. To defend important assets:

a. Restrict public access  

b. Add permissions carefully 

c. Use encryption for messages
