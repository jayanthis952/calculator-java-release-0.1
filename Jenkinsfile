pipeline {
    agent any

    environment {
        NEXUS_URL = "http://34.227.76.252:30002"
        ECR_REPO = "772317732952.dkr.ecr.us-east-1.amazonaws.com/calculator-java"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git url: 'https://github.com/jayanthis952/calculator-java-release-0.1.git', branch: 'main'
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Set Version & Repository') {
            steps {
                script {
                    // Get version from pom.xml
                    def VERSION = sh(
                        script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                        returnStdout: true
                    ).trim()
                    echo "Project version: ${VERSION}"
                    env.VERSION = VERSION
                    env.DOCKER_IMAGE = "calculator-java:${VERSION}"

                    // Choose Nexus repository based on version type
                    if (VERSION.endsWith('-SNAPSHOT')) {
                        env.NEXUS_REPO = 'maven-snapshots'
                    } else {
                        env.NEXUS_REPO = 'maven-releases'
                    }
                    echo "Using Nexus repository: ${env.NEXUS_REPO}"
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    script {
                        echo "Uploading to Nexus repository: ${env.NEXUS_REPO}"
                        nexusArtifactUploader(
                            nexusVersion: 'nexus3',
                            protocol: 'http',
                            nexusUrl: "${NEXUS_URL.replaceAll('http://','')}",
                            groupId: 'com.example',
                            version: "${env.VERSION}",
                            repository: "${env.NEXUS_REPO}",
                            credentialsId: 'nexus-creds',
                            artifacts: [
                                [artifactId: 'calculator-java', classifier: '', file: "target/calculator-java-${env.VERSION}.jar", type: 'jar']
                            ]
                        )
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        docker build \
                        --build-arg NEXUS_USER=${NEXUS_USER} \
                        --build-arg NEXUS_PASS=${NEXUS_PASS} \
                        --build-arg NEXUS_URL=${NEXUS_URL} \
                        --build-arg VERSION=${env.VERSION} \
                        -t ${env.DOCKER_IMAGE} .
                    """
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        aws configure set default.region us-east-1

                        aws ecr get-login-password | docker login --username AWS --password-stdin 772317732952.dkr.ecr.us-east-1.amazonaws.com
                        docker tag ${env.DOCKER_IMAGE} ${ECR_REPO}:${env.VERSION}
                        docker push ${ECR_REPO}:${env.VERSION}
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
