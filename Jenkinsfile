pipeline {
    agent any

    stages {
        stage("Checkout SCM") {
            steps {
                script {
                    def gitVars = checkout scm
                    COMMIT_ID = gitVars.GIT_COMMIT
                    echo "The commit ID is ${COMMIT_ID}"
                }
            }
        }

        stage("Build") {
            steps {
                script {
                    echo "Building the application..."
                }
            }
        }

        stage("Push to Docker Hub") {
            steps {
                script {
                    echo "Pushing the application to Docker Hub..."
                }
            }
        }

        stage("Update manifest file") {
            steps {
                script {
                    echo "Updating the manifest file..."
                }
            }
        }

        stage("Deploy to EKS") {
            steps {
                script {
                    echo "Deploying the application to EKS..."
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Cleaning up..."
            }
        }
    }
}