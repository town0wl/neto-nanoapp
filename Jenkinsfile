pipeline {
  agent {
    kubernetes {
      //cloud 'kubernetes'
      defaultContainer 'kaniko'
      yaml '''
        kind: Pod
        spec:
          containers:
          - name: kaniko
            image: gcr.io/kaniko-project/executor:v1.6.0-debug
            imagePullPolicy: IfNotPresent
            command:
            - sleep
            args:
            - 99d
            volumeMounts:
              - name: jenkins-docker-cfg
                mountPath: /kaniko/.docker
          - name: helm
            image: alpine/helm:3.10.2
            imagePullPolicy: IfNotPresent
            command:
            - sleep
            args:
            - 99d
          volumes:
          - name: jenkins-docker-cfg
            projected:
              sources:
              - secret:
                  name: jenkins-to-cr-push
                  items:
                    - key: .dockerconfigjson
                      path: config.json
'''
    }
  }
  environment {
    tagname = """${sh(
                returnStdout: true,
                script: 'if [ -n "${TAG_NAME}" ]; then printf "${TAG_NAME}"; else printf "${BUILD_TAG}"; fi'
            )}"""
  }
  stages {
    stage('Check Tag') {
      when { tag '' }
      steps {
        sh '''env
        if [ -n "${TAG_NAME}" ]; then printf "this:${TAG_NAME}"; else printf "this:${BUILD_TAG}"; fi
        '''
      }
    }
    stage('Build and push image with Kaniko') {
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh '''#!/busybox/sh
            /kaniko/executor --verbosity debug --force -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=cr.yandex/crprjg8fv1rv4n557ieq/nanoapp:${tagname}
          '''
        }
      }
    }
    stage('Install Test Deploy') {
      steps {
        container('helm') {
          sh '''helm install nanoapp-test --namespace test --set image.tag=${tagname} ./nanoapp-chart'''
        }
      }
    }
    stage('Wait') {
      steps {
          sh '''sleep 10'''
      }
    }
    stage('Install to App') {
      when { tag '' }
      steps {
        container('helm') {
          sh '''helm upgrade --install nanoapp --namespace app --set image.tag=${tagname} ./nanoapp-chart'''
        }  
      }
    }
  }
  post {
    cleanup {
      container('helm') {
        sh '''helm uninstall nanoapp-test --namespace test'''
      }
    }
  }
}