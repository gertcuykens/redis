#!/bin/bash
GO111MODULE=on go mod vendor
docker build -t gertcuykens/redis . --target root
docker push gertcuykens/redis
kubectl delete -f test.yml
kubectl apply -f test.yml
# docker run -it --rm gertcuykens/redis

# docker build -t gertcuykens/redis . --target debug --build-arg TOKEN=""
# docker run -it --rm \
#     -v $(GOPATH):/go \
#     -w $(subst $(GOPATH),/go,$(CURDIR)) \
#     -p 2345:2345 \
#     --security-opt apparmor=unconfined \
#     --cap-add SYS_PTRACE \
#     --privileged \
#     gertcuykens/redis ash

# kubectl create secret docker-registry registry \
#   --docker-server=https://index.docker.io/v1/ \
#   --docker-username=... \
#   --docker-password=... \
#   --docker-email=...
