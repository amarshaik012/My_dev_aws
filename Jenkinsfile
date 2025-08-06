pipeline {
    agent any

    environment {
        AWS_REGION          = 'us-east-1'
        AWS_ACCOUNT_ID      = '************'#Add Account ID
        ECR_REPO_NAME       = 'aws_dev'
        ECR_URI             = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
        IMAGE_TAG           = "v1-${BUILD_NUMBER}"
        CLUSTER_NAME        = 'my-cluster'
        AWS_CREDENTIALS_ID  = 'aws-jenkins-creds'
        PATH                = "/usr/local/bin:$PATH"
        SLACK_CHANNEL       = '#jenkins-alerts'
        SLACK_CREDENTIAL_ID = 'slack_jenkin'
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
                    if ! command -v aws &> /dev/null; then
                        echo "Installing AWS CLI..."
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip -o awscliv2.zip
                        sudo ./aws/install || sudo /usr/bin/aws/install
                    else
                        echo "AWS CLI already installed"
                    fi
                '''
            }
        }

        stage('Install kubectl (if missing)') {
            steps {
                sh '''
                    if ! command -v kubectl &> /dev/null; then
                        echo "Installing kubectl..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        sudo mv kubectl /usr/local/bin/
                    else
                        echo "kubectl already installed"
                    fi
                '''
            }
        }

        stage('Install Helm (if missing)') {
            steps {
                sh '''
                    if ! command -v helm &> /dev/null; then
                        echo "Installing Helm..."
                        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    else
                        echo "Helm already installed"
                    fi
                '''
            }
        }

        stage('Docker Build & Tag') {
            steps {
                sh """
                    docker build -t ${ECR_REPO_NAME}:latest .
                    docker tag ${ECR_REPO_NAME}:latest ${ECR_URI}:${IMAGE_TAG}
                """
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
                        kubectl set image deployment/my-app aws-dev-hnws4=${ECR_URI}:${IMAGE_TAG}
                        kubectl rollout status deployment/my-app
                    """
                }
            }
        }

        stage('Deploy Monitoring (Prometheus & Grafana)') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS_ID}"]]) {
                    sh '''
                        aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

                        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
                        helm repo add grafana https://grafana.github.io/helm-charts || true
                        helm repo update

                        if ! helm list -n monitoring | grep -q prometheus; then
                            echo "🚀 First-time Prometheus install..."
                            kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/crds/crd-servicemonitors.yaml || true
                            kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/main/charts/kube-prometheus-stack/crds/crd-prometheusrules.yaml || true
                            helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
                                --namespace monitoring \
                                --create-namespace \
                                -f monitoring/prometheus-values.yaml
                        else
                            echo "🔄 Updating existing Prometheus..."
                            helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
                                --namespace monitoring \
                                -f monitoring/prometheus-values.yaml
                        fi

                        echo "📊 Deploying Grafana..."
                        helm upgrade --install grafana grafana/grafana \
                            --namespace monitoring \
                            --create-namespace \
                            -f monitoring/grafana-values.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment succeeded: ${ECR_URI}:${IMAGE_TAG}"
            slackSend(
                channel: "${SLACK_CHANNEL}",
                message: "✅ *Deployment Succeeded*\n*Image:* `${ECR_URI}:${IMAGE_TAG}`\n*Job:* `${JOB_NAME}`\n*Build:* `${BUILD_NUMBER}`",
                color: 'good',
                tokenCredentialId: "${SLACK_CREDENTIAL_ID}"
            )
        }

        failure {
            echo "❌ Deployment failed."
            slackSend(
                channel: "${SLACK_CHANNEL}",
                message: "❌ *Deployment Failed*\n*Job:* `${JOB_NAME}`\n*Build:* `${BUILD_NUMBER}`\nCheck Jenkins logs for details.",
                color: 'danger',
                tokenCredentialId: "${SLACK_CREDENTIAL_ID}"
            )
        }
    }
}
