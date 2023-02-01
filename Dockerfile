FROM ubuntu:18.04

ARG delay_to=127.0.0.1

WORKDIR /app
RUN apt-get update && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:longsleep/golang-backports && \
    apt-get update && \
    apt-get install golang-go iproute2 -y
COPY go.* ./

RUN go mod download

COPY *.go ./

RUN go build -o /reqrouting-spam

EXPOSE 9080

# b-v1: tc qdisc add dev eth0 root handle 1: prio; tc filter add dev eth0 parent 1:0 protocol ip prio 1 u32 match ip dst 10.244.1.7 flowid 2:1; tc qdisc add dev eth0 parent 1:1 handle 2: netem delay 100ms
# a-v1: tc qdisc add dev eth0 root handle 1: prio; tc filter add dev eth0 parent 1:0 protocol ip prio 1 u32 match ip dst 10.244.1.8 flowid 2:1; tc qdisc add dev eth0 parent 1:1 handle 2: netem delay 100ms
CMD [ "/reqrouting-spam" ]
