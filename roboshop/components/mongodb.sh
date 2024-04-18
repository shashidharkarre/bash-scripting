#!/bin/bash
set -e 
COMPONENT=mongodb  
LOGFILE="/tmp/$COMPONENT.log"
MONGODB_REPO_URL="https://raw.githubusercontent.com/stans-robot-project/mongodb/main/mongo.repo"
COMPONENT_REPO="https://github.com/stans-robot-project/mongodb/archive/main.zip"

source components/common.sh 

echo -n "Downloading the $COMPONENT Repo:  "
curl -s -o /etc/yum.repos.d/mongodb.repo $MONGODB_REPO_URL
stat $? 

echo -n "Installing $COMPONENT: "
yum install -y mongodb-org &>> $LOGFILE
stat $? 

echo -n "Updating $COMPONENT Listenting address: "
sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
stat $? 

echo -n "starting $COMPONENT"
systemctl enable mongod  &>> $LOGFILE
systemctl restart mongod &>> $LOGFILE 
stat $?

echo -n "Downloading the $COMPONENT code: "
curl -s -L -o /tmp/mongodb.zip "$COMPONENT_REPO"
stat $? 

cd /tmp
echo -n "Extracting the schema: "
unzip -o mongodb.zip  &>> $LOGFILE 
stat $? 

cd mongodb-main
echo -n "Injecting the schema: "
mongo < catalogue.js &>> $LOGFILE 
mongo < users.js &>> $LOGFILE 
stat $?

echo -e " ____________________ \e[32m $COMPONENT Configuration is completed ____________________ \e[0m"
