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

        stage("Run unit tests") {
            steps {
                script {
                    echo "Running unit tests..."
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                        pytest test_app.py -v --cov=app --cov-report=term-missing
                    '''
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

        stage("Push to Container Registry") {
            steps {
                script {
                    echo "Pushing the application to Container Registry..."
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