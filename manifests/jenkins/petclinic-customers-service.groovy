pipeline {
    agent {
        kubernetes {
            yaml'''
apiVersion: v1
kind: Pod
metadata:
name: mvn-builder
spec:
containers:
- name: dind
    image: docker:28.0.0-dind-alpine3.21
    securityContext:
    privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
        value: ""
- name: mvn-builder
    image: annamartin123/mavendp:latest # image contains maven, docker, and syft
    env:
    - name: DOCKER_HOST
        value: "tcp://127.0.0.1:2375"
'''
            defaultContainer 'mvn-builder'
            retries 2
        }
    }
    environment {
        PUSH_IMAGE_REGISTRY = 'annamartin123'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], userRemoteConfigs: [[ credentialsId: 'gh-token'],[url: 'https://github.com/tw0-face/petclinic']])
            }
        }

        stage('Docker Login') {
            steps {
                sh "gcloud auth print-access-token --impersonate-service-account jenkins-sa | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev"
            }
        }

        stage('Sonarqube Scan') {
            steps {
                dir('petclinic-customers-service') {
                    script {
                        withSonarQubeEnv(installationName: 'SONARQUBE') {
                            sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=petclinic-customers-service -Dsonar.projectName=petclinic-customers-service'
                        }
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                dir('petclinic-customers-service') {
                    sh 'mvn clean package'
                    sh 'mvn spring-boot:build-image'
                    junit '**/target/surefire-reports/TEST*.xml'
                }
            }
        }

        stage('Push Image and SBOM') {
            steps {
                script {
                    def IMAGE_TAG = sh(
                        script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout',
                        returnStdout: true
                    ).trim()

                    def DOCKERREPO = "${PUSH_IMAGE_REGISTRY}/petclinic-customers-service"
                    def DOCKER_IMAGE = "${DOCKERREPO}:${IMAGE_TAG}"

                    dir('petclinic-customers-service') {
                        sh "docker push ${DOCKER_IMAGE}"
                        sh "syft ${DOCKER_IMAGE} -o cyclonedx-json=cyclonedx.json"
                        
                        sh 'echo "image=${DOCKER_IMAGE}" > image.properties'
                        sh 'echo "messageFormat=DOCKER" >> image.properties'
                        sh 'echo "customFormat=false" >> image.properties'
                        archiveArtifacts artifacts: 'image.properties', fingerprint: true

                        withCredentials([
                            string(credentialsId: 'dependency-track-api-token', variable: 'API_KEY')
                        ]) {
                            dependencyTrackPublisher(
                                artifact: './cyclonedx.json',
                                projectName: 'petclinic-customers-service',
                                projectVersion: IMAGE_TAG,
                                dependencyTrackApiKey: API_KEY
                            )
                        }
                    }
                }
            }
        }

        
}
}