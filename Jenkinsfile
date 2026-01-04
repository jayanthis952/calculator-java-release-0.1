pipeline {
    agent any

    environment {
        PROJECT_KEY     = "java-calculator-k8s"
        VERSION         = "1.0.${BUILD_NUMBER}"
        IMAGE_NAME      = "calculator-java"

        AWS_REGION      = "us-east-1"
        AWS_ACCOUNT_ID  = "772317732952"
        ECR_REPO        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

        NEXUS_URL       = "http://98.85.254.195:30002/"
        NEXUS_REPO      = "maven-releases"
        GROUP_ID        = "com.example"
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/jayanthis952/calculator-java-release-0.1.git'
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
                success {
                    echo "✅ Quality Gate Passed"
                }
                failure {
                    echo "❌ Quality Gate Failed"
                }
            }
        }

        stage('Build Application') {
            steps {
                sh """
                mvn clean install -Drevision=${VERSION}
                """
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: '98.85.254.195:30002',
                    repository: "${NEXUS_REPO}",
                    credentialsId: 'nexus-creds',
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}",
                    artifacts: [
                        [
                            artifactId: 'calculator-java',
                            classifier: '',
                            file: "target/calculator-java-${VERSION}.jar",
                            type: 'jar'
                        ]
                    ]
                )
            }
        }

        stage('Docker Image Build') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {
                    sh """
                    docker build \
                      --build-arg NEXUS_URL=${NEXUS_URL} \
                      --build-arg NEXUS_USERNAME=${NEXUS_USER} \
                      --build-arg NEXUS_PASSWORD=${NEXUS_PASS} \
                      --build-arg ARTIFACT_VERSION=${VERSION} \
                      -t ${IMAGE_NAME}:${VERSION} .
                    """
                }
            }
        }

        stage('Push Image to AWS ECR') {
            steps {
                withAWS(credentials: 'aws-ecr-creds', region: "${AWS_REGION}") {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                    docker tag ${IMAGE_NAME}:${VERSION} ${ECR_REPO}:${VERSION}
                    docker push ${ECR_REPO}:${VERSION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Docker image pushed successfully to ECR"
            echo "📦 Image: ${ECR_REPO}:${VERSION}"
        }
        failure {
            echo "🔥 Pipeline execution failed"
        }
    }
}
