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



helm install -n nfs-provisioner nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.0.150.91 \
    --set nfs.path=/nfs/vanilla \
    --set storageClass.onDelete=delete \
    --set storageClass.pathPattern='${.PVC.namespace}/${.PVC.name}' \ #'${.PVC.namespace}/${.PVC.name}'
    --set storageClass.provisionerName=storage.io/nfs \
    --set storageClass.name=nfs-sc \
    --set storageClass.archiveOnDelete=false \
    --set storageClass.defaultClass=true 
