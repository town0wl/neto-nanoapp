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
  stages {
    stage('Check Tag') {
      when { tag "*" }
      steps {
        sh 'env'
      }
    }
    stage('Env') {
      steps {
        sh 'env'
      }
    }
    stage('Clone') {
      steps {
        git branch: 'main', url: 'https://github.com/town0wl/neto-nanoapp.git'
      }
    }
    stage('Build and push image with Kaniko') {
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh '''#!/busybox/sh
            /kaniko/executor --verbosity debug --force -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=cr.yandex/crprjg8fv1rv4n557ieq/nanoapp:${BUILD_TAG}
          '''
        }
      }
    }
    stage('Install Test Deploy') {
      steps {
        container('helm') {
          sh '''helm install ${BUILD_TAG} --namespace test --set image.tag=${BUILD_TAG} ./nanoapp-chart'''
        }
      }
    }
    stage('Wait') {
      steps {
          sh '''sleep 10'''
      }
    }
  }
  post {
    cleanup {
      container('helm') {
        sh '''helm uninstall ${BUILD_TAG} --namespace test'''
      }
    }
  }
}