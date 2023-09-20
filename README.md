# SonarQubeLocal
Simple self contained sonarqube scanning.

To use this tool copy the .env.template to .env and add the desired gitrepo to GIT_REPO.

For example to scan the https://github.com/KageRyu7/SonarQubeLocal repo it would need the following.
```GIT_REPO=git@github.com:KageRyu7/SonarQubeLocal.git```

Once that file is created simply run ./scan.sh

An instance of sonarqube will appear at http://sonarqube:9000
The login information is
    username: admin
    password: KageRyu7

The script will clone the git repo locally, and then run a scanning tool pointing to sonarqube.
Log into sonarqube:9000 and go to projects. The project will be named after the git repo.