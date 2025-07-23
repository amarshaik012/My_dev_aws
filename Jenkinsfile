pipeline {
    agent any
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '669370114932.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'aws_dev'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }
        stage('Login to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }
        stage('Tag and Push Image') {
            steps {
                sh '''
                    docker tag ${IMAGE_NAME}:latest ${ECR_REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${ECR_REGISTRY}/${IMAGE_NAME}:latest
                '''
            }
        }
        stage('Deploy to EKS') {
            steps {
                sh '''
                    kubectl set image deployment/my-app aws-dev-hnws4=${ECR_REGISTRY}/${IMAGE_NAME}:latest
                    kubectl rollout status deployment/my-app
                '''
            }
        }
    }
}
