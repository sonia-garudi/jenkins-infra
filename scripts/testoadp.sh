#!/bin/bash +x

cd ${WORKSPACE}
echo "${BASTION_IP} api.${KUB_SERVER_URL} oauth-openshift.apps.${KUB_SERVER_URL}" >> /etc/hosts

echo 'Install golang'
git clone https://github.com/ocp-power-automation/ocp4-playbooks-extras
cd ocp4-playbooks-extras
cp examples/go_lang_installation_vars.yaml go_lang_installation_vars.yaml 
sed -i "s|golang_tarball_url:.*$|golang_tarball_url: https://dl.google.com/go/go1.18.linux-amd64.tar.gz|g" go_lang_installation_vars.yaml
sed -i "s|golang_installation:.*$|golang_installation: true|g" go_lang_installation_vars.yaml
cp examples/inventory ./e2e_inventory
ansible-playbook  -i e2e_inventory -e @go_lang_installation_vars.yaml playbooks/golang-installation.yml
rc=$?
if [ $rc -ne 0 ] ; then
  echo 'Golang installation failed'
  exit
fi
export GOROOT=/usr/local/go
export PATH=/usr/local/go/bin:$PATH
export GOBIN=/usr/local/go/bin

#Run e2e
echo 'Run E2E'
cd ${WORKSPACE}
git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-e2e-qe.git && cd oadp-e2e-qe
sudo apt update && sudo apt install build-essential -y
go install github.com/onsi/ginkgo/v2/ginkgo@latest


exit


echo 'Login to OCP cluster'
cd ${WORKSPACE}
wget https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest-4.12/openshift-client-linux-amd64.tar.gz
tar -xvzf openshift-client-linux-amd64.tar.gz
export PATH=$PATH:${WORKSPACE}
oc login --token=${KUB_TOKEN} --server=https://api.${KUB_SERVER_URL}:6443 --insecure-skip-tls-verify
oc get nodes

sed -i 's/\r//' ${INSTALL_OPTS_FILE}
source ${INSTALL_OPTS_FILE}
cd ${WORKSPACE} && rm -rf oadp-qe-automation
git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-qe-automation
	
#Install OADP operator
if [[ "$INSTALL_OADP" == "true" ]] ; then
	echo 'Install OADP operator'	
	cd ${WORKSPACE} && cd oadp-qe-automation
	bash operator/oadp/deploy_oadp.sh 2>&1 | tee deploy-oadp.log
	rc=$?
	if [ $rc -ne 0 ] ; then
	  echo 'OADP operator installation failed'
	fi
	oc get csv -n openshift-adp
fi

if [[ "$INSTALL_VOLSYNC" == "true" ]] ; then
	echo 'Install Volsync operator'
	cd ${WORKSPACE} && cd oadp-qe-automation
	bash operator/volsync/deploy_volsync.sh 2>&1 | tee deploy-volsync.log
	rc=$?
	if [ $rc -ne 0 ] ; then
	  echo 'Volsync operator installation failed'
	fi
	oc get csv -n openshift-adp
fi

#Run e2e
echo 'Run E2E'
git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-e2e-qe.git && cd oadp-e2e-qe
sudo yum update -y && sudo yum install gcc
go install github.com/onsi/ginkgo/v2/ginkgo@latest && go install github.com/onsi/gomega/...
