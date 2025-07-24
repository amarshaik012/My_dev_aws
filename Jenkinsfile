pipeline {
    agent any

    environment {
        AWS_REGION     = 'us-east-1'
        ECR_REGISTRY   = '669370114932.dkr.ecr.us-east-1.amazonaws.com'
        IMAGE_NAME     = 'aws_dev'
        SLACK_CHANNEL  = '#ci-cd'
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
                    def shortCommit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "${BUILD_NUMBER}-${shortCommit}"
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Tag & Push Docker Image') {
            steps {
                script {
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                dir('terraform') {
                    script {
                        sh "terraform init -input=false"
                        sh "terraform plan -input=false -out=tfplan"
                        sh "terraform apply -input=false -auto-approve tfplan"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    // Update kubeconfig with your EKS cluster name
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name my-cluster"

                    // Replace <IMAGE_URI> with actual image URI in manifest
                    sh """
                    sed -i 's|<IMAGE_URI>|${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}|g' k8s/deployment.yaml
                    kubectl apply -f k8s/deployment.yaml
                    """
                }
            }
        }
    }

    post {
        success {
            script {
                slackSend(
                    channel: "${SLACK_CHANNEL}",
                    color: 'good',
                    message: "✅ Build #${BUILD_NUMBER} succeeded and deployed `${IMAGE_NAME}:${IMAGE_TAG}` to EKS cluster `my-cluster`."
                )
            }
        }
        failure {
            script {
                slackSend(
                    channel: "${SLACK_CHANNEL}",
                    color: 'danger',
                    message: "❌ Build #${BUILD_NUMBER} failed. Check Jenkins logs for details."
                )
            }
        }
    }
}
