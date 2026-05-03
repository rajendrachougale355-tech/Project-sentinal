pipeline {
    agent any

    environment {
        // AWS variables (not used in this pipeline but kept for future ECR push)
        AWS_ACCOUNT_ID = '556791123713'
        AWS_REGION     = 'ap-south-1'
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        // Docker Hub variables
        DOCKER_HUB_USER = 'rajchouugale'
        IMAGE_NAME      = 'project-sentinel-app'
        IMAGE_TAG       = 'v1'
    }

    stages {
        stage('Build Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'rajchouugale', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "docker login -u ${USER} -p ${PASS}"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy to App Server') {
            steps {
                sshCommand remote: [
                    name: 'app-server',
                    host: '10.0.2.111',
                    user: 'ec2-user',
                    identityFile: '/var/lib/jenkins/Project_key.pem'
                ],
                command: """
                    sudo docker stop sentinel-app || true
                    sudo docker rm sentinel-app || true
                    sudo docker pull ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                    sudo docker run -d -p 80:80 --name sentinel-app ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
