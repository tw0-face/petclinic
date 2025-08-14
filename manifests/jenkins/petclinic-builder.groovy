pipeline {
    triggers {
        githubPush()
    }
    agent any
    stages {
        
        stage('checkout') {
            steps{
                checkout scmGit(branches: [[name: '*/main']], userRemoteConfigs: [[ credentialsId: 'gh-token'],[url: 'https://github.com/tw0-face/petclinic']])
            
            }
            }
            
        stage('Build petclinic-frontend') {
            when {
                changeset "petclinic-frontend/**"
            }
            steps {
                build wait: false, job: 'petclinic-frontend'
            }
        }
        stage('Build petclinic-vets-service') {
            when {
                changeset "petclinic-vets-service/**"
            }
            steps {
                build wait: false, job: 'petclinic-vets-service'
            }
        }

        stage('Build petclinic-customers-service') {
            when {
                changeset "petclinic-customers-service/**"
            }
            steps {
                build wait: false, job: 'petclinic-customers-service'
            }
        }

        stage('Build petclinic-visits-service') {
            when {
                changeset "petclinic-visits-service/**"
            }
            steps {
                build wait: false, job: 'petclinic-visits-service'
            }
        }
    }
}
