#!/bin/bash

echo ${KUB_SERVER_URL}
echo ${KUB_TOKEN}
cd ${WORKSPACE}
wget https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest-4.12/openshift-client-linux-amd64.tar.gz
tar -xvzf openshift-client-linux-amd64.tar.gz

oc login --token=${KUB_TOKEN} --server=${KUB_SERVER_URL}
oc get nodes


git clone https://github.ibm.com/Sonia-Garudi1/oadp-qe-automation
