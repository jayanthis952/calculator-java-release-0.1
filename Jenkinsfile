pipeline {
    agent any
    environment {
        PROJECT_KEY = "java-calculator-k8s"
        VERSION = "1.0.${env.BUILD_NUMBER}"
        IMAGE_NAME = "calculator-java"
    }
    stages {

        stage('SCM') {
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
                success {
                    echo "Quality Gate Passed"
                }
                failure {
                    echo "Quality Gate Failed"
                }
            }
        }

        stage('Build') {
            steps {
                sh """mvn clean install -Drevision=${VERSION}"""
            }
        }

        stage('Nexus Artifactory') {
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
                    nexusUrl: '34.227.76.252:30002',   // FIXED: removed extra http://
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: 'maven-releases',
                    version: "${VERSION}"
                )
            }
        }

        stage('Docker Image Build') {
            agent any
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
                        --build-arg NEXUS_URL=http://34.227.76.252:30002 \
                        --build-arg NEXUS_USER=$NEXUS_USER \
                        --build-arg NEXUS_PASS=$NEXUS_PASS \
                        --build-arg VERSION=${VERSION} \
                        -t ${IMAGE_NAME}:${VERSION} .
                    """
                }
            }
        }

        stage('Image to ECR') {
            agent any
            steps {
                withAWS(credentials: 'jenkins-ecr', region: 'us-east-1') {
                    sh """
                        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 772317732952.dkr.ecr.us-east-1.amazonaws.com
                        docker tag ${IMAGE_NAME}:${VERSION} 772317732952.dkr.ecr.us-east-1.amazonaws.com/calculator-java:${VERSION}
                        docker push 772317732952.dkr.ecr.us-east-1.amazonaws.com/calculator-java:${VERSION}
                    """
                }
            }
        }

    }
}
