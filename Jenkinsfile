pipeline {
    agent any

    environment {
        PROJECT_KEY     = "java-calculator-k8s"
        VERSION         = "1.0.${BUILD_NUMBER}"
        IMAGE_NAME      = "calculator-java"

        AWS_REGION      = "us-east-1"
        AWS_ACCOUNT_ID  = "772317732952"
        ECR_REPO        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"

        NEXUS_URL       = "http://3.94.114.187:30002"
        NEXUS_REPO      = "maven-releases1"
        GROUP_ID        = "com.example"

        GITOPS_REPO     = "https://github.com/jayanthis952/calculator-java-gitops.git"
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
        }

        stage('Build Application') {
            steps {
                sh "mvn clean install -Drevision=${VERSION}"
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: '54.144.8.25:30002',
                    repository: "${NEXUS_REPO}",
                    credentialsId: 'nexus-creds',
                    groupId: "${GROUP_ID}",
                    version: "${VERSION}",
                    artifacts: [
                        [
                            artifactId: 'calculator-java',
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
                        usernameVariable: 'NEXUS_USERNAME',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    sh """
                    docker build \
                      --build-arg NEXUS_URL=${NEXUS_URL} \
                      --build-arg NEXUS_USERNAME=${NEXUS_USERNAME} \
                      --build-arg NEXUS_PASSWORD=${NEXUS_PASSWORD} \
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

        stage('Update Image in GitOps Repo') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )
                ]) {
                    sh """
                    rm -rf calculator-java-gitops
                    git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/jayanthis952/calculator-java-gitops.git
                    cd calculator-java-gitops

                    sed -i 's|image:.*|image: ${ECR_REPO}:${VERSION}|' pod.yaml

                    git config user.name "jenkins"
                    git config user.email "jenkins@devops.com"

                    git add pod.yaml
                    git commit -m "Update image to ${VERSION}"
                    git push
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Image pushed to ECR and GitOps repo updated"
        }
        failure {
            echo "❌ Pipeline execution failed"
        }
    }
}
