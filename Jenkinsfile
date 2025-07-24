pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '669370114932'
        ECR_REPO_NAME = 'aws_dev'
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
        IMAGE_TAG = "v1-${BUILD_NUMBER}"
        CLUSTER_NAME = 'my-cluster'
        AWS_CREDENTIALS_ID = 'aws-jenkins-creds' // Update with your Jenkins AWS credential ID
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/amarshaik012/My_dev_aws.git'
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    sh "docker build -t ${ECR_URI}:${IMAGE_TAG} ."
                }
            }
        }

        stage('AWS Auth & ECR Login') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        sh """
                            aws configure set default.region ${AWS_REGION}
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
                        """
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh "docker push ${ECR_URI}:${IMAGE_TAG}"
                }
            }
        }

        stage('Update K8s Deployment') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    script {
                        sh """
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
            echo "✅ Deployed successfully: ${ECR_URI}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Deployment failed"
        }
    }
}
