pipeline {
    agent any
    environment {
        // AWS variables
        AWS_ACCOUNT_ID = '556791123713'
        AWS_REGION     = 'ap-south-1'
        ECR_URL        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        
        // Docker Hub variables
        DOCKER_HUB_USER = 'your_dockerhub_username' // Change this
        IMAGE_NAME      = 'project-sentinel-app'
        IMAGE_TAG       = 'v1'
    }
    stages {
        // ... Previous stages (Checkout, Build, ECR Push) ...

        stage('Push to Docker Hub') {
            steps {
                // Use the credentials ID we created in Step 1
                withCredentials([usernamePassword(credentialsId: 'rajchouugale', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "docker login -u ${USER} -p ${PASS}"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
    }
}
