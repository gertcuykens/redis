#!/bin/bash

if [ "$1" == "apply" ]
then
    cat redis-x.yml | (export NR=0; ./template.sh) > redis-0.yml
    cat redis-x.yml | (export NR=1; ./template.sh) > redis-1.yml
    cat redis-x.yml | (export NR=2; ./template.sh) > redis-2.yml
    cat redis-x.yml | (export NR=3; ./template.sh) > redis-3.yml
    cat redis-x.yml | (export NR=4; ./template.sh) > redis-4.yml
    cat redis-x.yml | (export NR=5; ./template.sh) > redis-5.yml
    for i in {0..5}
    do
        POD=redis-$i
        kubectl apply -f $POD.yml
    done
    exit 0
fi

if [ "$1" == "delete" ]
then
    if [ "$2" == "" ]; then kubectl delete pod -l app=redis; rm -r /tmp/redis*; exit 0; fi
    POD=redis-${2:-0}
    kubectl delete pod $POD
    # rm -r /tmp/$POD*;
    exit 0
fi

if [ "$1" == "list" ]
then
    kubectl get pods -l app=redis
    exit 0
fi

if [ "$1" == "create" ]
then
    REPLICAS=${2:-1}
    POD=redis-${3:-0}
    HOSTS=$(kubectl get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP}:6379 ')
    kubectl exec -it $POD -- redis-cli --cluster create $HOSTS --cluster-replicas $REPLICAS
    exit 0
fi

if [ "$1" == "check" ]
then
    POD=redis-${2:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    # kubectl exec -it $POD -- redis-cli --cluster info $POD_IP
    kubectl exec -it $POD -- redis-cli --cluster check $POD_IP
    # kubectl exec $POD -- redis-cli cluster nodes
    exit 0
fi

if [ "$1" == "fix" ]
then
    POD=redis-${2:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    kubectl exec -it $POD -- redis-cli --cluster fix $POD_IP
    exit 0
fi

if [ "$1" == "nodes" ] || [ "$1" == "slots" ]
then
    REDUCE="myself"
    if [ "$1" == "slots" ]; then REDUCE="myself,master"; fi
    PODS=$(kubectl get pods -l app=redis | awk 'NR>1 {print $1}')
    for POD in $PODS; do
        MYSELF=$(kubectl exec $POD -- redis-cli cluster nodes | grep $REDUCE)
        if [ ! -z "$MYSELF" ]; then echo "$POD $MYSELF"; fi
    done
    exit 0
fi

if [ "$1" == "fails" ]
then
    PODS=$(kubectl get pods -l app=redis | awk 'NR>1 {print $1}')
    for POD in $PODS; do
        echo
        echo "======== $POD ========"
        echo
        kubectl exec $POD -- redis-cli cluster nodes | grep fail
    done
    exit 0
fi

if [ "$1" == "logs" ]
then
    PODS=$(kubectl get pods -l app=redis| awk 'NR>1 {print $1}')
    for POD in $PODS; do
        echo
        echo "======== $POD ========"
        echo
        kubectl logs $POD
    done
    exit 0
fi

if [ "$1" == "ping" ]
then
    PODS=$(kubectl get pods -l app=redis | awk 'NR>1 {print $1}')
    for POD in $PODS; do
        echo -n "$POD "
        # POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
        # kubectl exec $POD -- redis-cli --cluster call $POD_IP ping
        kubectl exec $POD -- redis-cli ping
    done
    exit 0
fi

if [ "$1" == "master" ] || [ "$1" == "slave" ]
then
    SLAVE="--cluster-slave"
    if [ "$1" == "master" ]; then SLAVE=""; fi
    NEW_IP=$(kubectl get pod redis-$2 -o jsonpath='{.status.podIP}'):6379
    POD=redis-${3:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    kubectl exec $POD -- redis-cli --cluster add-node $NEW_IP $POD_IP $SLAVE
    exit 0
fi

if [ "$1" == "rm" ]
then
    ID=$(kubectl exec redis-$2 -- redis-cli cluster nodes | grep myself | awk '{print $1}')
    POD=redis-${3:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    kubectl exec $POD -- redis-cli --cluster del-node $POD_IP $ID
    exit 0
fi

if [ "$1" == "forget" ]
then
    PODS=$(kubectl get pods -l app=redis | awk 'NR>1 {print $1}')
    for POD in $PODS; do
        kubectl exec $POD -- redis-cli cluster forget $2
    done
    exit 0
fi

if [ "$1" == "rebalance" ]
then
    POD=redis-${2:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    kubectl exec $POD -- redis-cli --cluster rebalance $POD_IP --cluster-use-empty-masters
    exit 0
fi

if [ "$1" == "reshard" ]
then
    POD=redis-${4:-0}
    POD_IP=$(kubectl get pod $POD -o jsonpath='{.status.podIP}'):6379
    kubectl exec $POD -- redis-cli --cluster reshard --cluster-yes \
    --cluster-from $2 \
    --cluster-to $3 \
    --cluster-slots 16384 $POD_IP
    exit 0
fi

if [ "$1" == "backup" ]
then
    NAMESPACE=${2:-default}
    PODS=$(kubectl get pods -l app=redis | awk 'NR>1 {print $1}')
    for POD in $PODS; do
        echo -n "$POD "
        kubectl exec $POD -- redis-cli save
        kubectl cp $NAMESPACE/$POD:$POD.rdb backup/$POD.rdb
    done
    exit 0
fi

# if [ "$1" == "restore" ]
# then
#     exit 0
# fi

if [ "$1" == "cli" ]
then
    POD=redis-${2:-0}
    kubectl exec -it $POD -- redis-cli
    exit 0
fi

echo "Usage: $0 [apply|delete|create|list|nodes|fails|slots|check|fix|logs|ping|master|slave|rm|forget|rebalance|reshard|backup|cli]"
echo "apply      -- Apply Redis pods."
echo "delete     -- Delete Redis pods."
echo "scale      -- Scale <NR> Redis pods."
echo "create     -- Create Redis cluster <POD_NR>."
echo "list       -- List all Redis pods."
echo "nodes      -- List CLUSTER NODES for all Redis pods."
echo "fails      -- List failed CLUSTER NODES for all Redis pods."
echo "slots      -- List all Redis slots <POD_NR>."
echo "check      -- Check Redis cluster <POD_NR>."
echo "fix        -- Fix Redis cluster <POD_NR>."
echo "logs       -- Show logs for all Redis pods."
echo "ping       -- Ping each Redis pod."
echo "master     -- Add master <POD_NR> to cluster <POD_NR>."
echo "slave      -- Add slave <POD_NR> to cluster <POD_NR>."
echo "rm         -- Remove Redis <POD_NR> from cluster <POD_NR>."
echo "forget     -- Remove Redis node <ID> from cluster."
echo "rebalance  -- Rebalance Redis cluster <POD_NR>."
echo "reshard    -- Reshard Redis master <POD_NR> to Redis master <POD_NR>."
echo "backup     -- Copy rdb files from kubernets to backup folder."
echo "restore    -- Restore rdb files from backup folder."
echo "cli        -- Redis cli <POD_NR>."
