pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '669370114932'
        ECR_REPO_NAME = 'aws_dev'
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
        IMAGE_TAG = "v1-${BUILD_NUMBER}"
        CLUSTER_NAME = 'my-cluster'
        AWS_CREDENTIALS_ID = 'aws-jenkins-creds'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/amarshaik012/My_dev_aws.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        echo "🔧 Building Docker image..."
                        docker build -t ${ECR_REPO_NAME}:latest .
                        docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Configure AWS CLI') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    script {
                        sh """
                            echo "⚙️ Configuring AWS CLI..."
                            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                            aws configure set default.region ${AWS_REGION}
                        """
                    }
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    script {
                        sh """
                            echo "🔐 Logging in to Amazon ECR..."
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_URI}
                        """
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        echo "📦 Pushing Docker image to ECR..."
                        docker push ${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    script {
                        sh """
                            echo "📡 Updating Kubernetes deployment..."
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                            kubectl set image deployment/aws-dev aws-dev=${ECR_URI}:${IMAGE_TAG} --record
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Successfully deployed: ${ECR_URI}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}
