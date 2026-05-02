pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = '556791123713'
        AWS_REGION     = 'ap-south-1'
        IMAGE_REPO     = 'sentinel-app'
        IMAGE_TAG      = 'v1'
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        APP_SERVER_IP  = '10.0.2.203' // Replace with your Private App Server IP
    }
    stages {
        stage('Build & Push to ECR') {
            steps {
                // Authenticate and Push using the IAM Role on the Jenkins EC2
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                sh "docker build -t ${IMAGE_REPO}:${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_REPO}:${IMAGE_TAG} ${ECR_URL}/${IMAGE_REPO}:${IMAGE_TAG}"
                sh "docker push ${ECR_URL}/${IMAGE_REPO}:${IMAGE_TAG}"
            }
        }
        stage('Deploy to Private Subnet') {
            steps {
                sshagent(['sentinel-ssh-key']) {
                    // Pull the new image on the private server via SSH
                    sh "ssh -o StrictHostKeyChecking=no ${APP_SERVER_IP} 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL} && docker pull ${ECR_URL}/${IMAGE_REPO}:${IMAGE_TAG} && docker run -d -p 80:80 ${ECR_URL}/${IMAGE_REPO}:${IMAGE_TAG}'"
                }
            }
        }
    }
}
