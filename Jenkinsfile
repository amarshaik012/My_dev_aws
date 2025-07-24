pipeline {
    agent any

    environment {
        IMAGE_TAG = "4-${GIT_COMMIT.take(7)}"
        AWS_REGION = "us-east-1"
        ECR_REGISTRY = "669370114932.dkr.ecr.us-east-1.amazonaws.com"
        ECR_REPOSITORY = "aws_dev"
        SLACK_CHANNEL = "#jenkinbottAPP"
        SLACK_TOKEN_ID = "slack-token"
    }

    options {
        ansiColor('xterm')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh "sed -i '' 's|<IMAGE>|${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}|' k8s/deployment.yaml"
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name my-cluster"
                    sh "kubectl apply -f k8s/"
                }
            }
        }
    }

    post {
        success {
            slackSend (
                channel: "${env.SLACK_CHANNEL}",
                message: "✅ Build & Deployment successful: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                tokenCredentialId: "${env.SLACK_TOKEN_ID}"
            )
        }
        failure {
            slackSend (
                channel: "${env.SLACK_CHANNEL}",
                message: "❌ Build failed: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                tokenCredentialId: "${env.SLACK_TOKEN_ID}"
            )
        }
    }
}
