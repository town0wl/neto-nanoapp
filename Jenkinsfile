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
            env:
              - name: LOCAL_REGISTRY_ID
                valueFrom:
                  configMapKeyRef:
                    name: registry-id
                    key: registry-id
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
            env:
              - name: LOCAL_REGISTRY_ID
                valueFrom:
                  configMapKeyRef:
                    name: registry-id
                    key: registry-id
          - name: multitool
            image: praqma/network-multitool:alpine-extra
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
    stage('Build and push image with Kaniko') {
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh '''#!/busybox/sh
            /kaniko/executor --verbosity debug --force -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=cr.yandex/"${LOCAL_REGISTRY_ID}"/nanoapp:${tagname}
          '''
        }
      }
    }
    stage('Install Test Deploy') {
      when { not { tag '' } }
      steps {
        container('helm') {
          sh '''helm install nanoapp-test --namespace test --set image.repository=cr.yandex/"${LOCAL_REGISTRY_ID}"/nanoapp --set image.tag=${tagname} --set 'ingress.hosts[0].host=test.leto131.ru,ingress.hosts[0].paths[0].path=/,ingress.hosts[0].paths[0].pathType=Prefix' ./nanoapp-chart'''
        }
      }
    }
    stage('Test HTTP') {
      when { not { tag '' } }
      steps {
        container('multitool') {
          sh '''sleep 10
            curl http://nanoapp-test-nanoapp-chart.test.svc.public.cluster/
          '''
        }
      }
    }
    stage('Install to App') {
      when { tag '' }
      steps {
        container('helm') {
          sh '''helm upgrade --install nanoapp --namespace app --set image.repository=cr.yandex/"${LOCAL_REGISTRY_ID}"/nanoapp --set image.tag=${tagname} ./nanoapp-chart'''
        }  
      }
    }
    stage('Test Prod in App') {
      when { tag '' }
      steps {
        container('multitool') {
          sh '''sleep 10
            curl http://nanoapp-nanoapp-chart.app.svc.public.cluster/
          '''
        }
      }
    }
  }
  post {
    cleanup {
      container('helm') {
        sh '''helm uninstall nanoapp-test --namespace test || true'''
      }
    }
  }
}