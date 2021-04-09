# Premise
* Terraform v0.13.4
* AmazonWebService
* you have a nice domain
    * create host_zone in route53 (https://console.aws.amazon.com/route53/v2/hostedzones#)

# TODO

```bash
$ aws confiure
# bucketname is a globally unique name
$ aws s3 mb s3://iac-code
```

# Constitution

## 1. common
<code>terraform init --var-file=config.tfvars</code>
<code>terraform plan --var-file=config.tfvars</code>
<code>terraform apply --var-file=config.tfvars</code>

* S3
* CodeCommit
* ECR
* CodeBuild
* CodePipeline
* DNS(Certificate/Route53)
* GlobalDNS(Certificate/Route53)

## 2. modules
these files are used by different environments.

## 3. ww9
<code>terraform init --var-file=config.tfvars</code>
<code>terraform plan --var-file=config.tfvars</code>
<code>terraform apply --var-file=config.tfvars</code>

this is a staging environment.

### 4. www
<code>terraform init --var-file=config.tfvars</code>
<code>terraform plan --var-file=config.tfvars</code>
<code>terraform apply --var-file=config.tfvars</code>

this is a production environment.
