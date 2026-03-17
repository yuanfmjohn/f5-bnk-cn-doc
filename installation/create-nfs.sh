echo "install CSI driver for NFS ..."
helm repo update
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --set kubeletDir=/var/lib/kubelet
kubectl get pods --selector app.kubernetes.io/name=csi-driver-nfs --namespace kube-system
kubectl apply -f storageclass.yaml
kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
