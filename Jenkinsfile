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
        PATH = "/usr/local/bin:$PATH"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/amarshaik012/My_dev_aws.git'
            }
        }

        stage('Install AWS CLI (if missing)') {
            steps {
                sh '''
                    if ! command -v aws &> /dev/null
                    then
                        echo "Installing AWS CLI..."
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip -o awscliv2.zip
                        sudo ./aws/install
                    else
                        echo "AWS CLI already installed"
                    fi
                '''
            }
        }

        stage('Docker Build & Tag') {
            steps {
                script {
                    sh """
                        docker build -t ${ECR_REPO_NAME}:latest .
                        docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_URI}
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push ${ECR_URI}:${IMAGE_TAG}"
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh """
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                        kubectl set image deployment/aws-dev aws-dev=${ECR_URI}:${IMAGE_TAG} --record
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment succeeded: ${ECR_URI}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}
