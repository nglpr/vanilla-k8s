helm upgrade --install gitlab gitlab/gitlab -n gitlab-system\
  --timeout 600s \
  --set global.hosts.domain=k8s.nglp.tech \
  --set global.hosts.externalIP=10.0.150.12 \
  --set certmanager-issuer.email=nglpr.tech@gmail.com \
  --set postgresql.image.tag=13.6.0



helm install -n nfs-provisioner nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.0.150.91 \
    --set nfs.path=/nfs \
    --set storageClass.onDelete=delete \
    --set storageClass.pathPattern='${.PVC.namespace}/${.PVC.name}' \ #'${.PVC.namespace}/${.PVC.name}'
    --set storageClass.provisionerName=storage.io/nfs \
    --set storageClass.name=nfs-sc \
    --set storageClass.archiveOnDelete=false \
    --set storageClass.defaultClass=true 
