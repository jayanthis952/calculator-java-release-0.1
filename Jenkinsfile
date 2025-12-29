pipeline{
    agent {label 'node2'}
    environment{
        PROJECT_KEY="java-calculator-k8s"
        VERSION="1.0.${env.BUILD_NUMBER}"
        IMAGE_NAME="calculator-java"
    }
    stages{
        stage('SCM'){
            steps{
                git branch: 'main', url: 'https://github.com/Agasthyahm/calculator-java-release.git'
            }
        }
        stage('sonar analysis'){
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
        stage('Quality gate validate'){
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
                sh """ mvn clean install \
                       -Drevision=${VERSION} """
            }
        }
        stage('Nexus-artifactory'){
            steps{
                nexusArtifactUploader artifacts: [[artifactId: 'calculator-java', classifier: '', file: "target/calculator-java-${VERSION}.jar", type: 'jar']],
                    credentialsId: 'nexus-cred', groupId: 'com.example', nexusUrl: '16.16.104.141:30003', nexusVersion: 'nexus3', protocol: 
                    'http', repository: 'maven-releases', version: "${VERSION}"
            }
        }
        stage('docker image build'){
            agent {label 'node3'}
            steps{
                withCredentials([usernamePassword(credentialsId: 'nexus-cred',usernameVariable: 'NEXUS_USER',passwordVariable: 'NEXUS_PASS')])
                {  
                    sh """
                         docker build \
                         --build-arg NEXUS_URL=http://16.16.104.141:30003 \
                         --build-arg NEXUS_USER=$NEXUS_USER \
                         --build-arg NEXUS_PASS=$NEXUS_PASS \
                         --build-arg VERSION=${VERSION} \
                         -t ${IMAGE_NAME}:${VERSION} .
                     """
                }
           }
        }
    }
}
