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

echo 'Try login to OCP cluster'
cd ${WORKSPACE}
echo 'Download oc client'
wget https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest-4.12/openshift-client-linux-amd64.tar.gz
tar -xvzf openshift-client-linux-amd64.tar.gz
export PATH=$PATH:${WORKSPACE}
oc login --token=${KUB_TOKEN} --server=https://api.${KUB_SERVER_URL}:6443 --insecure-skip-tls-verify
rc=$?
if [ $rc -ne 0 ] ; then
  echo 'Login to cluster failed'
  exit
fi
oc get nodes


echo $OADP_CREDS_FILE > ${WORKSPACE}/aws_creds

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
	  exit 1
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
	  exit 1
	fi
	oc get csv -n openshift-adp
fi

#Run e2e
if [[ "$RUN_E2E" == "true" ]] ; then
	echo 'Run E2E'
	cd ${WORKSPACE}
	rm -rf oadp-e2e-qe
	git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-e2e-qe.git
	echo 'Clone OCP deployer dependency'
	cd ${WORKSPACE}
	git clone https://${GIT_USERNAME}:${GIT_TOKEN}@github.ibm.com/Sonia-Garudi1/oadp-apps-deployer.git
	cd oadp-apps-deployer && git checkout master && cd ${WORKSPACE}
	cp -R ${WORKSPACE}/oadp-apps-deployer/src/ocpdeployer ${WORKSPACE}/oadp-e2e-qe/sample-applications/
	cd ${WORKSPACE}/oadp-e2e-qe
	echo 'InstallE2E dependenicies'
	sudo apt update && sudo apt install build-essential -y
	go install github.com/onsi/ginkgo/v2/ginkgo@v2.7.0
	pip install kubernetes
	echo 'Run e2e suite'
	sed -i "s/MUST_GATHER_BUILD=\"must_gather_image\"/MUST_GATHER_BUILD=\"brew.registry.redhat.io\/rh-osbs\/oadp-oadp-mustgather-rhel8:1.1.2-26\"/" test_settings/scripts/test_runner.sh
	EXTRA_GINKGO_PARAMS="--ginkgo.focus=Verify\slog\slevel\spanic"  /bin/bash test_settings/scripts/test_runner.sh | tee test.log
	cat test.log
fi