pipeline {
    agent any

    environment {
        VERSION = "1.0.16"
        NEXUS_URL = "34.227.76.252:30002"   // just the host:port
        NEXUS_USER = credentials('nexus-user') // Jenkins credentials ID for Nexus username
        NEXUS_PASS = credentials('nexus-pass') // Jenkins credentials ID for Nexus password
        AWS_ACCOUNT_ID = "772317732952"
        AWS_REGION = "us-east-1"
        ECR_REPO = "calculator-java"
        IMAGE_TAG = "${VERSION}"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build with Maven') {
            steps {
                sh "mvn clean package -DskipTests"
            }
        }

        stage('Upload to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusUrl: "http://${NEXUS_URL}",
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: 'maven-releases',
                    credentialsId: 'nexus-creds', // Jenkins credentials ID for Nexus
                    groupId: 'com.example',
                    version: "${VERSION}",
                    artifacts: [[
                        artifactId: 'calculator-java',
                        classifier: '',
                        type: 'jar',
                        file: "target/calculator-java-${VERSION}.jar"
                    ]]
                )
            }
        }

        stage('Docker Build') {
            steps {
                withCredentials([
                    string(credentialsId: 'nexus-user', variable: 'NEXUS_USER'),
                    string(credentialsId: 'nexus-pass', variable: 'NEXUS_PASS')
                ]) {
                    sh """
                        docker build \
                            --build-arg NEXUS_USER=${NEXUS_USER} \
                            --build-arg NEXUS_PASS=${NEXUS_PASS} \
                            --build-arg NEXUS_URL=http://${NEXUS_URL} \
                            --build-arg VERSION=${VERSION} \
                            -t ${ECR_REPO}:${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set default.region ${AWS_REGION}

                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
