# Master Nodes
for host in master{0..1}.k8s.nglp.tech; do
  ssh-copy-id root@$host
done

# Worker Nodes
for host in worker{0..1}.k8s.nglp.tech; do
  ssh-copy-id root@$host
done


kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --control-plane-endpoint=endpoint.k8s.nglp.tech \
  --cri-socket=/var/run/crio/crio.sock \
  --upload-certs

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p $HOME/.kube
scp -r user@remote.host.domain:/path/user/.kube .
cp -r .kube $HOME/

helm upgrade --install gitlab gitlab/gitlab -n gitlab-system\
  --timeout 600s \
  --set global.hosts.domain=k8s.nglp.tech \
  --set global.hosts.externalIP=10.0.150.12 \
  --set certmanager-issuer.email=nglpr.tech@gmail.com \
  --set postgresql.image.tag=13.6.0

=======================================================

helm install -n nfs-provisioner nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.0.150.91 \
    --set nfs.path=/nfs/vanilla \
    --set storageClass.onDelete=delete \
    --set storageClass.pathPattern='${.PVC.namespace}/${.PVC.name}' \ #'${.PVC.namespace}/${.PVC.name}'
    --set storageClass.provisionerName=storage.io/nfs \
    --set storageClass.name=nfs-sc \
    --set storageClass.archiveOnDelete=false \
    --set storageClass.defaultClass=true 

===============================

oc adm policy add-scc-to-user privileged -z default -n nfs-provisioner

========================================================

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: nfs-sc
  annotations:
    storageclass.kubernetes.io/is-default-class: 'true'
provisioner: k8s-sigs.io/nfs
parameters:
  onDelete: delete
  pathPattern: '${.PVC.namespace}/${.PVC.name}'
  archiveOnDelete: false
reclaimPolicy: Delete
volumeBindingMode: Immediate

============================================================

apiVersion: apps.gitlab.com/v1beta2
kind: Runner
metadata:
 name: main
spec:
 gitlabUrl: https://gitlab.apps.okd.nglp.tech
 buildImage: alpine
 token: gitlab-project-runner-secret
 tags: openshift
 ca: star-apps-okd-nglp-tech
 config: custom-config-toml
 
 =========================================
 
 sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.apps.okd.nglp.tech/" \
  --registration-token "GR1348941fZSyv9cevetAzx9A4nBH" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "project-docker-runner" \
  --maintenance-note "Free-form maintainer notes about this runner" \
  --tag-list "docker,aws" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected" \
  --docker-privileged \
  --tls-ca-file cert/ca.cert

====================================================

# This file is a template, and might need editing before it works on your project.
docker-build-master:
  # Official docker image.
  image: docker:latest
  stage: build
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - docker build --pull -t "$CI_REGISTRY_IMAGE" .
    - docker push "$CI_REGISTRY_IMAGE"
  only:
    - master

docker-build:
  # Official docker image.
  image: docker:latest
  stage: build
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - docker build --pull -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
  except:
    - master

=================================================

variables:
  DOCKER_IMAGE_NAME: nglpr/nginx-image
  DOCKER_IMAGE_TAG: latest

stage-build:
  image: docker:23-dind
  stage: build
  
  services:
    - name: docker:dind
      entrypoint: ["env", "-u", "DOCKER_HOST"]
      command: ["entrypoint.sh"]

  variables:
    DOCKER_HOST: tcp://docker:2375/
    DOCKER_DRIVER: overlay2
    DOCKER_TLS_CERTDIR: ""
  
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  
  script:
    - docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .
    - docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
    
 =================================================
    
    triggers:
    - type: ConfigChange
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
          - cicd
        from:
          kind: ImageStreamTag
          namespace: kopi
          name: 'cicd:latest'
