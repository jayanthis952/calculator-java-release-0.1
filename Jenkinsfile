pipeline {
    agent any
    environment {
        PROJECT_KEY = "java-calculator-k8s"
        VERSION = "1.0.${env.BUILD_NUMBER}"
        IMAGE_NAME = "calculator-java"
        NEXUS_URL = "http://34.227.76.252:30002"
        ECR_REPO = "772317732952.dkr.ecr.us-east-1.amazonaws.com/calculator-java"
        AWS_REGION = "us-east-1"
    }
    stages {

        stage('Checkout SCM') {
            steps {
                git branch: 'main', url: 'https://github.com/jayanthis952/calculator-java-release-0.1.git'
            }
        }

        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('sonar-k8s') {
                    sh """mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${PROJECT_KEY} \
                        -Dsonar.projectName=${PROJECT_KEY} \
                        -Drevision=${VERSION}"""
                }
            }
        }

        stage('Quality Gate Validate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
            post {
                success { echo "Quality Gate Passed" }
                failure { echo "Quality Gate Failed" }
            }
        }

        stage('Build Maven Artifact') {
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
                    nexusUrl: '34.227.76.252:30002',
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

        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-creds',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh """
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region ${AWS_REGION}
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag ${IMAGE_NAME}:${VERSION} ${ECR_REPO}:${VERSION}
                        docker push ${ECR_REPO}:${VERSION}
                    """
                }
            }
        }

    }
}
