pipeline {
    agent any

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Kalpanavaddepalli/devops-code-challenge2.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t my-app ./app'
            }
        }

        stage('Login to ECR') {
            steps {
                echo "Login step here"
            }
        }

        stage('Push to ECR') {
            steps {
                echo "Push step here"
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "Deploy step here"
            }
        }
    }
}
