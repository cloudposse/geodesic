#!/bin/bash

cfssl gencert -initca ca.json | cfssljson -bare ca
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem server.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem agent.json | cfssljson -bare agent

kubectl create secret generic kiam-server-tls -n kube-system \
  --from-file=ca.pem \
  --from-file=server.pem \
  --from-file=server-key.pem

kubectl create secret generic kiam-agent-tls -n kube-system \
  --from-file=ca.pem \
  --from-file=agent.pem \
  --from-file=agent-key.pem

chamber write kops KIAM_AGENT_TLS_KEY `cat agent-key.pem | base64 -w 0`
chamber write kops KIAM_AGENT_TLS_CERT `cat agent.pem | base64 -w 0`
chamber write kops KIAM_AGENT_TLS_CA `cat ca.pem | base64 -w 0`

chamber write kops KIAM_SERVER_TLS_KEY `cat server-key.pem | base64 -w 0`
chamber write kops KIAM_SERVER_TLS_CERT `cat server.pem | base64 -w 0`
chamber write kops KIAM_SERVER_TLS_PA `cat ca.pem | base64 -w 0`
