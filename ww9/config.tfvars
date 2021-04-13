env            = "ww9"
id             = "000000000000"
image          = "000000000000.dkr.ecr.ap-northeast-1.amazonaws.com/testservice-app"
DB_NAME        = "testserviceDB"
DB_ROOT        = "niceyourusername"
DB_PASSWORD    = "youhavetomakeacomplexnicepassword"
vpc_cidr_block = "10.50.0.0/16"
instance_class = "db.t3.small"
s3_img_bucket  = "testservice-ww9-img"
cf_name        = "testservice.testdomainissbeautiful.com"
# after you created subnets
db_subnet      = "subnet-00000000000000000"
region         = "ap-northeast-1"
service_name   = "testservice"
domain_name    = "testdomainissbeautiful.com"