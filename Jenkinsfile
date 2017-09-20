// https://jenkins.io/doc/book/pipeline/
// Inspired by Lachlan Evenson https://github.com/lachie83/croc-hunter/blob/master/Jenkinsfile

//Lets define a unique label for this build.
def label = "buildpod.${env.JOB_NAME}.${env.BUILD_NUMBER}".replace('-', '_').replace('/', '_')

podTemplate(label: label, containers: [
    containerTemplate(name: 'jnlp', image: 'jenkins/jnlp-slave:alpine', args: '${computer.jnlpmac} ${computer.name}', workingDir: '/home/jenkins', resourceRequestCpu: '200m', resourceLimitCpu: '200m', resourceRequestMemory: '256Mi', resourceLimitMemory: '512Mi'),
    containerTemplate(name: 'docker', image: 'docker:1.12.6', command: 'cat', ttyEnabled: true),
    containerTemplate(name: 'make', image: 'andrey01/make:0.2', command: 'cat', ttyEnabled: true),
  ],
  volumes:[
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
  ],)
{

  node (label) {

    stage ('Checkout repo') {
      checkout scm
    }

    sh 'git rev-parse HEAD > git_commit_id.txt'
    try {
      env.GIT_COMMIT_ID = readFile('git_commit_id.txt').trim()
      env.GIT_SHA = env.GIT_COMMIT_ID.substring(0, 7)
    } catch (e) {
      error "${e}"
    }
    println "env.GIT_COMMIT_ID ==> ${env.GIT_COMMIT_ID}"

    container('make') {
      stage ('Build') {
        sh "VERSION=${env.GIT_SHA} make"
      }

      stage ('Test') {
        sh "VERSION=${env.GIT_SHA} make check"
      }

      if (env.BRANCH_NAME == 'master') {
        // perform docker login to Docker Hub as the docker-pipeline-plugin doesn't work with the next auth json format
        // withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: config.container_repo.jenkins_creds_id,
        //  sh "docker login -e ${config.container_repo.dockeremail} -u ${env.USERNAME} -p ${env.PASSWORD}"
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'my-dockerhub-creds',
                        usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
          sh "docker login -u ${env.USERNAME} -p ${env.PASSWORD}"
        }

        stage ('Deploy') {
          sh "VERSION=${env.GIT_SHA} make publish"
        }

        sh 'docker logout'

      } else {
        println "Current branch ${env.BRANCH_NAME}"
      }

    } // node

  } // PodTemplate

}
