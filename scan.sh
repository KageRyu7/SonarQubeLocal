#! /bin/bash

source .env
WORK_DIR=$(pwd)
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FOLDER_NAME=$(basename $GIT_REPO | sed 's/.git//')
FOLDER_PATH=$SCRIPT_DIR/$FOLDER_NAME

prepareRepoFolder() {
    # $1 = git repository
    # $2 = name of local git folder
    # $2 = path to local git folder
    if [ ! -d $3 ]; then
        echo "[Pulling git repo]"
        git clone $1 >> /dev/null
    fi

    # Create properties file in folder
    sed "s/<<ProjectName>>/$2/g" $SCRIPT_DIR/sonar-project.properties.template > $3/sonar-project.properties
}

prepareRepoFolderAnew() {
    # $1 = git repository
    # $2 = name of local git folder
    # $2 = path to local git folder
    if [ -d $3 ]; then
        echo "[Remove existing git repo]"
        rm -rf $3
    fi
    echo "[Pulling git repo]"
    git clone $1 >> /dev/null

    # Create properties file in folder
    sed "s/<<ProjectName>>/$2/g" $SCRIPT_DIR/sonar-project.properties.template > $3/sonar-project.properties
}

startSonarQube() {
    # # Check for sonarqube container
    SONARQUBE=$(docker ps | grep "sonarqube" | wc -l)
    if [[ "$SONARQUBE" -eq 0 ]]; then
        CONATINER_EXISTS=$(docker container ls -a | grep sonarqube | wc -l)
        if [[ "$CONATINER_EXISTS" -eq 1 ]]; then
            docker container rm sonarqube
        fi

        NETWORKEXISTS=$(docker network ls | grep sonarqube | wc -l)
        if [[ "$NETWORKEXISTS" -eq 0 ]]; then
            echo "[Creating sonarqube network]"
            docker network create sonarqube
        fi

        # Sonarqube container not running, lets start it
        echo "[Starting Sonarqube]"
        docker run -d --rm \
            --name sonarqube \
            --network sonarqube \
            -p 9000:9000 \
            kageryu7/sonarqube
    fi
}

waitForSonarQube() {
    # Check sonarqube container exists
    SONARQUBE=$(docker ps | grep "sonarqube" | wc -l)
    if [[ "$SONARQUBE" -eq 0 ]]; then
        echo 'ERROR: Sonarqube container does not exist'
        exit 1
    fi

    # Check sonarqube is up and ready
    echo "[Waiting for SonarQube to start]"
    while [ true ]
    do
        STATUS=$(curl -s http://localhost:9000/api/system/status | grep "UP" | wc -l)
        if [[ "$STATUS" -eq 1 ]]; then
            echo '[Sonarqube ready]'
            break
        fi
        sleep 5
    done
}

runSonarScan() {
    # Run scan containers
    docker container rm sonar-scanner-cli 2&> /dev/null
    echo '[Running Scan]'
    docker run \
        --rm \
        --name sonar-scanner \
        --network sonarqube \
        -v $1:/usr/src \
        sonarsource/sonar-scanner-cli
}

cd $SCRIPT_DIR
prepareRepoFolder $GIT_REPO $FOLDER_NAME $FOLDER_PATH
# Ensure we cd back to where we began
cd $WORK_DIR

startSonarQube
waitForSonarQube
runSonarScan $FOLDER_PATH
