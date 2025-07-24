pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        IMAGE_NAME = 'my-app'
        ECR_REPO = '123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app'
        SLACK_CHANNEL = '#jenkinbottAPP'
        SLACK_CREDENTIALS_ID = 'slack-webhook-token'  // Set this in Jenkins credentials
        CLUSTER_NAME = 'my-eks-cluster'
        K8S_NAMESPACE = 'default'
    }

    stages {
        stage('Clone Repo') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo 'Logging in to ECR...'
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        docker tag $IMAGE_NAME:latest $ECR_REPO:latest
                        docker push $ECR_REPO:latest
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    script {
                        echo 'Running Terraform...'
                        sh '''
                            terraform init
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    echo 'Updating kubeconfig and deploying to EKS...'
                    sh '''
                        aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
                        kubectl set image deployment/my-app-deployment my-app-container=$ECR_REPO:latest -n $K8S_NAMESPACE
                        kubectl rollout status deployment/my-app-deployment -n $K8S_NAMESPACE
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', message: "✅ Job *${env.JOB_NAME}* #${env.BUILD_NUMBER} succeeded and deployed to EKS.")
        }
        failure {
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', message: "❌ Job *${env.JOB_NAME}* #${env.BUILD_NUMBER} failed.")
        }
    }
}
