#!/bin/bash

echo ${KUB_SERVER_URL}
echo ${KUB_TOKEN}
cd ${WORKSPACE}
oc login --token=${KUB_TOKEN} --server=${KUB_SERVER_URL}
oc get nodes


git clone https://github.ibm.com/Sonia-Garudi1/oadp-qe-automation
