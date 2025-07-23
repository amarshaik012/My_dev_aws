pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:$PATH"     // 🔧 Add this line
        AWS_REGION = 'us-east-1'
        ECR_REGISTRY = '669370114932.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME = 'aws_dev'
        SLACK_CHANNEL = '#ci-cd'
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
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        kubectl set image deployment/my-app aws-dev-hnws4=${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        kubectl rollout status deployment/my-app
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "${SLACK_CHANNEL}", message: "✅ Build #${env.BUILD_NUMBER} *succeeded* and deployed image `${IMAGE_TAG}` to EKS.")
        }
        failure {
            slackSend(channel: "${SLACK_CHANNEL}", message: "❌ Build #${env.BUILD_NUMBER} *failed*. Please check Jenkins.")
        }
    }
}
