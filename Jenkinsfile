pipeline{
    agent any
    environment{
        PROJECT_KEY="java-calculator-k8s"
        VERSION="1.0.${env.BUILD_NUMBER}"
        IMAGE_NAME="calculator-java"
        NEXUS_URL="http://34.227.76.252:30002"
        ECR_REPO="772317732952.dkr.ecr.us-east-1.amazonaws.com/calculator-java"
    }
    stages{
        stage('SCM'){
            steps{
                git branch: 'main', url: 'https://github.com/jayanthis952/calculator-java-release-0.1.git'
            }
        }

        stage('Sonar Analysis'){
            steps{
                withSonarQubeEnv('sonar-k8s'){
                    sh """ mvn clean verify sonar:sonar \
                    -Dsonar.projectKey=${PROJECT_KEY} \
                    -Dsonar.projectName=${PROJECT_KEY} \
                    -Drevision=${VERSION}
                    """
                }
            }
        }

        stage('Quality Gate Validate'){
            steps{
                timeout(time: 5, unit: 'MINUTES'){
                    waitForQualityGate abortPipeline: true
                }
            }
            post{
                success{
                    echo "Quality Gate Passed"
                }
                failure{
                    echo "Quality Gate Failed"
                }
            }
        }

        stage('Build'){
            steps{
                sh "mvn clean install -Drevision=${VERSION}"
            }
        }

        stage('Upload to Nexus'){
            steps{
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]){
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: "${NEXUS_URL.replaceAll('http://','')}",
                        groupId: 'com.example',
                        version: "${VERSION}",
                        repository: 'maven-releases',
                        credentialsId: 'nexus-creds',
                        artifacts: [
                            [artifactId: 'calculator-java', classifier: '', file: "target/calculator-java-${VERSION}.jar", type: 'jar']
                        ]
                    )
                }
            }
        }

        stage('Docker Image Build'){
            agent any
            steps{
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]){
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

        stage('Push Docker Image to ECR'){
            agent any
            steps{
                withAWS(credentials:'aws-ecr-creds', region:'us-east-1'){
                    sh """
                        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag ${IMAGE_NAME}:${VERSION} ${ECR_REPO}:${VERSION}
                        docker push ${ECR_REPO}:${VERSION}
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
