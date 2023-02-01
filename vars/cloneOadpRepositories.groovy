def call() {
    script {
        ansiColor('xterm') {
            echo ""
        }
        try {
            // Run the script to setup kube config
            sh (returnStdout: false, script: "/bin/bash ${WORKSPACE}/scripts/testoadp.sh || true")
        }
        catch (err) {
            echo 'Error ! Kubectl setup  !'
            env.FAILED_STAGE=env.STAGE_NAME
            throw err
        }
    }
}
