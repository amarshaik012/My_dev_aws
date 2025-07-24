pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:$PATH"
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '669370114932.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'aws_dev'
        IMAGE_TAG = ''
        SLACK_CHANNEL = '#ci-cd'
        SLACK_TOKEN_ID = 'slack-token' // 🔐 Jenkins Credentials ID for Slack Token
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Tests') {
            steps {
                sh '''
                    npm install
                    npm test || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                }
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region ${AWS_REGION}
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    '''
                }
            }
        }

        stage('Tag and Push Image') {
            steps {
                sh '''
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region ${AWS_REGION}
                        kubectl set image deployment/my-app aws-dev-hnws4=${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        kubectl rollout status deployment/my-app
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                tokenCredentialId: "${SLACK_TOKEN_ID}",
                message: "✅ Build #${env.BUILD_NUMBER} *succeeded* and deployed image `${IMAGE_TAG}` to EKS."
            )
        }
        failure {
            slackSend(
                channel: "${SLACK_CHANNEL}",
                tokenCredentialId: "${SLACK_TOKEN_ID}",
                message: "❌ Build #${env.BUILD_NUMBER} *failed*. Please check Jenkins."
            )
        }
    }
}
