# Deployment template for full stack on AWS

## Setup

1. Clone this repo

2. AWS Setup:
    - Register a domain (`FRONTEND_DOMAIN`) with AWS and get the Hosted Zone Id in Route53 (`HOSTED_ZONE_ID`)
    - Request a certificate for your new domain with an additional wildcard subdomain & get the arn (`CERTIFICATE_ARN`)
    - Set up a role in AWS IAM for CloudFormation that has the permissions necessary to create your resources & get the arn (`CLOUDFORMATION_ROLE_ARN`)
    - Create an AWS IAM User for GitHub Actions with S3 access & get credentials(`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`)
    - Set up a Google Analytics account & web stream & get the tracking ID (`GA_TRACKING_ID`)

3. Add the following secrets in your GitHub repo
    - STACK_NAME
    - CERTIFICATE_ARN
    - FRONTEND_DOMAIN
    - HOSTED_ZONE_ID
    - CLOUDFORMATION_ROLE_ARN
    - AWS_REGION
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - GA_TRACKING_ID

4. Check out a new branch for development

5. Add code to frontend/ and backend/ as needed

6. When ready, merge your changes into the `main` branch

7. Monitor GitHub Actions and CloudFormation to see the progress of your deployment
