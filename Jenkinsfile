pipeline {
    agent any
    environment {
        PROJECT_KEY = "java-calculator-k8s"
        VERSION = "1.0.${env.BUILD_NUMBER}"
        IMAGE_NAME = "calculator-java"
        ECR_ACCOUNT = "772317732952"
        ECR_REGION = "us-east-1"
        ECR_REPO = "calculator-java"
        NEXUS_URL = "http://34.227.76.252:30002"
    }

    stages {
        stage('SCM Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/jayanthis952/calculator-java-release-0.1.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-k8s') {
                    sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${PROJECT_KEY} \
                        -Dsonar.projectName=${PROJECT_KEY} \
                        -Drevision=${VERSION}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
            post {
                success { echo "Quality Gate Passed" }
                failure { error "Quality Gate Failed" }
            }
        }

        stage('Build JAR') {
            steps {
                sh "mvn clean install -Drevision=${VERSION}"
            }
        }

        stage('Upload to Nexus') {
            steps {
                nexusArtifactUploader(
                    artifacts: [[
                        artifactId: 'calculator-java',
                        classifier: '',
                        file: "target/calculator-java-${VERSION}.jar",
                        type: 'jar'
                    ]],
                    credentialsId: 'nexus-creds',
                    groupId: 'com.example',
                    nexusUrl: "${NEXUS_URL}",
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: 'maven-releases',
                    version: "${VERSION}"
                )
            }
        }

        stage('Docker Build') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {  
                    sh """
                        docker build \
                        --build-arg NEXUS_URL=${NEXUS_URL} \
                        --build-arg NEXUS_USER=$NEXUS_USER \
                        --build-arg NEXUS_PASS=$NEXUS_PASS \
                        --build-arg VERSION=${VERSION} \
                        -t ${IMAGE_NAME}:${VERSION} .
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(credentials: 'jenkins-ecr', region: "${ECR_REGION}") {
                    script {
                        // Check if ECR repo exists, create if not
                        def repoExists = sh(
                            script: "aws ecr describe-repositories --repository-names ${ECR_REPO} || true",
                            returnStatus: true
                        )
                        if (repoExists != 0) {
                            sh "aws ecr create-repository --repository-name ${ECR_REPO} --region ${ECR_REGION}"
                        }

                        // Login and push image
                        sh """
                            aws ecr get-login-password --region ${ECR_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com
                            docker tag ${IMAGE_NAME}:${VERSION} ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${ECR_REPO}:${VERSION}
                            docker push ${ECR_ACCOUNT}.dkr.ecr.${ECR_REGION}.amazonaws.com/${ECR_REPO}:${VERSION}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully! Docker image pushed to ECR."
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
