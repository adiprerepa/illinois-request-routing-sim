#!/bin/bash

# delete qdisc rules
kubectl exec --stdin --tty deploy/a-v1 -- tc qdisc del dev eth0 root;
kubectl exec --stdin --tty deploy/b-v1 -- tc qdisc del dev eth0 root;


dst_delay_from_a=$(kubectl get pod $(kubectl get pods -l=app=b,version=v2 -o jsonpath='{.items[0].metadata.name}') -o jsonpath='{.status.podIP}')
dst_delay_from_b_v1=$(kubectl get pod $(kubectl get pods -l=app=c,version=v1 -o jsonpath='{.items[0].metadata.name}') -o jsonpath='{.status.podIP}')

echo "ip $dst_delay_from_a a-v1->b-v2"
echo "ip $dst_delay_from_b_v1 b-v1->c-v1"

kubectl exec --stdin --tty deploy/a-v1 -- tc qdisc add dev eth0 root handle 1: prio;
kubectl exec --stdin --tty deploy/a-v1 -- tc filter add dev eth0 parent 1:0 protocol ip prio 1 u32 match ip dst $dst_delay_from_a flowid 2:1;
kubectl exec --stdin --tty deploy/a-v1 -- tc qdisc add dev eth0 parent 1:1 handle 2: netem delay 50ms;


kubectl exec --stdin --tty deploy/b-v1 -- tc qdisc add dev eth0 root handle 1: prio;
kubectl exec --stdin --tty deploy/b-v1 -- tc filter add dev eth0 parent 1:0 protocol ip prio 1 u32 match ip dst $dst_delay_from_b_v1 flowid 2:1;
kubectl exec --stdin --tty deploy/b-v1 -- tc qdisc add dev eth0 parent 1:1 handle 2: netem delay 50ms;
