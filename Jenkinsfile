pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        ACCOUNT_ID = '669370114932'
        ECR_REPO = 'aws_dev'
        IMAGE_TAG = "latest"
        DEPLOYMENT_NAME = 'my-app'
        CONTAINER_NAME = 'aws-dev-hnws4'
        NAMESPACE = 'default'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "docker build -t $ECR_REPO:$IMAGE_TAG ."
            }
        }
        stage('Login to ECR') {
            steps {
                sh "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
            }
        }
        stage('Tag and Push Image to ECR') {
            steps {
                sh "docker tag $ECR_REPO:$IMAGE_TAG ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ECR_REPO:$IMAGE_TAG"
                sh "docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ECR_REPO:$IMAGE_TAG"
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh "kubectl set image deployment/$DEPLOYMENT_NAME $CONTAINER_NAME=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/$ECR_REPO:$IMAGE_TAG -n $NAMESPACE"
                sh "kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
            }
        }
    }
}

