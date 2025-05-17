# [Setup](https://docs.aws.amazon.com/cdk/v2/guide/getting_started.html)


## installation of npm 
```bash
sudo apt install npm
sudo npm install -g aws-cdk
cdk --version   
```

## cdk using python
`note`: pwd:= ParentDirectory
```bash
source .venv/bin/activate
python -m pip install -r aws-req.txt

cdk init app --language python
cdk bootstrap
cdk deploy  --verbose --progress bar
cdk destroy
```

## verify npm installation
```bash
npm list -g --depth=0
/usr/local/lib
└── aws-cdk@2.1003.0
aws sts get-caller-identity --query Account --output text
```


# Docker locally
`note`: pwd:= ParentDirectory
```bash
docker build -t lambdafn -f Dockerfile.lambdafn . # image_size: 2.71 GB
docker run --rm -it -p 8080:8080 lambdafn
```


## push image to ECR
```bash
# login
aws ecr get-login-password --region ${CDK_DEFAULT_REGION} | docker login --username AWS --password-stdin ${CDK_DEFAULT_ACCOUNT}.dkr.ecr.${CDK_DEFAULT_REGION}.amazonaws.com
# build
docker build --build-arg AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} --build-arg AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} --build-arg AWS_DEFAULT_REGION=${CDK_DEFAULT_REGION} -t lambdafn  -f Dockerfile.lambdafn .
# tag
docker tag lambdafn:latest ${CDK_DEFAULT_ACCOUNT}.dkr.ecr.${CDK_DEFAULT_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest

# test
docker run --rm -it -p 8080:8080 ${CDK_DEFAULT_ACCOUNT}.dkr.ecr.${CDK_DEFAULT_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest bash

# push
docker push ${CDK_DEFAULT_ACCOUNT}.dkr.ecr.${CDK_DEFAULT_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest
```

306093656765


cdk bootstrap aws://306093656765/ap-south-1
cdk deploy --require-approval=never


