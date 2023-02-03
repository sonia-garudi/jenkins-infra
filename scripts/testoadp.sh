#!/bin/bash +x

cd ${WORKSPACE}
echo "${BASTION_IP} api.${KUB_SERVER_URL} oauth-openshift.apps.${KUB_SERVER_URL}" >> /etc/hosts

#Install golang
git clone https://github.com/ocp-power-automation/ocp4-playbooks-extras
cd ocp4-playbooks-extras
cp examples/go_lang_installation_vars.yaml go_lang_installation_vars.yaml 
sed -i "s|golang_tarball:.*$|golang_tarball: https://dl.google.com/go/go1.18.linux-amd64.tar.gz|g" go_lang_installation_vars.yaml
sed -i "s|golang_installation:.*$|golang_installation: true|g" go_lang_installation_vars.yaml
cp examples/inventory ./e2e_inventory
ansible-playbook  -i e2e_inventory -e @go_lang_installation_vars.yaml playbooks/golang-installation.yml

cd ${WORKSPACE}
wget https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest-4.12/openshift-client-linux-amd64.tar.gz
tar -xvzf openshift-client-linux-amd64.tar.gz
export PATH=$PATH:${WORKSPACE}
oc login --token=${KUB_TOKEN} --server=https://api.${KUB_SERVER_URL}:6443 --insecure-skip-tls-verify
oc get nodes

#Install OADP operator
echo 'Clone oadp-qe-automation repository'
cd ${WORKSPACE} && rm -rf oadp-qe-automation
export GOROOT=/usr/local/go
export PATH=/usr/local/go/bin:$PATH
export GOBIN=/usr/local/go/bin
git clone https://Sonia-Garudi1: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@github.ibm.com/Sonia-Garudi1/oadp-qe-automation
#git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-qe-automation
cd oadp-qe-automation
export REPOSITORY='prestage'
export IP_APPROVAL='Automatic'
export STREAM='downstream'
export OADP_VERSION="1.1.2"
export IIB_IMAGE='iib:422341'
bash operator/oadp/deploy_oadp.sh 2>&1 | tee deploy-oadp.login
rc=$?
if [ $rc -ne 0 ] ; then
  echo 'Operator installation failed'
fi
oc get csv -n openshift-adp