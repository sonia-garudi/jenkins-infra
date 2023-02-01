#!/bin/bash 

set -x

echo ${KUB_SERVER_URL}
echo ${KUB_TOKEN}
cd ${WORKSPACE}
wget https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest-4.12/openshift-client-linux-amd64.tar.gz
tar -xvzf openshift-client-linux-amd64.tar.gz

export PATH=$PATH:${WORKSPACE}

echo "${BASTION_IP} api.${KUB_SERVER_URL} oauth-openshift.apps.${KUB_SERVER_URL}" >> /etc/hosts


oc login --token=${KUB_TOKEN} --server=https://api.${KUB_SERVER_URL}:6443
oc get nodes


git clone https://Sonia-Garudi1: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@github.ibm.com/Sonia-Garudi1/oadp-qe-automation
