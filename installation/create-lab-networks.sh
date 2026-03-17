#!/bin/bash

echo ""
echo "Creating docker networks sf-external and attach both to worker nodes ..."
docker network create -d macvlan sf-external --subnet 19.0.2.0/24

docker network connect sf-external bnk-worker
docker network connect sf-external bnk-worker2
docker network connect sf-external bnk-worker3

echo "Flush IP on eth1 in each worker node, the node won't use it, only TMM will"
for node in $(docker ps --format "{{.Names}}" | grep "worker"); do
  echo -n $node
  docker exec -ti $node ip a flush eth1
done
