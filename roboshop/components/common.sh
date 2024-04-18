#!/bin/bash 

USER_ID=$(id -u)
if [ $USER_ID -ne 0  ] ; then  
    echo -e "\e[31m You need to run it as a root user only \e[0m"
    exit 1
fi 

stat() {
    if [ $1 -eq 0 ] ; then 
        echo -e " \e[32m SUCCESS \e[0m"
    else 
        echo -e " \e[31m FAILURE \e[0m"
    fi 
}

PYTHON(){
    echo -n "Installing Python: "
    yum install python36 gcc python3-devel -y  &>> $LOGFILE  
    stat $? 

    #Calling user creation function
    CREATE_USER

    # Calling Function 
    DOWNLOAD_AND_EXTRACT 

    echo -n "Installing $COMPONENT: "
    pip3 install -r requirements.txt &>> $LOGFILE  
    stat $?

    echo -n "Updating the App Config $COMPONENT.ini: "
    USER_ID=$(id -u roboshop)
    GROUP_ID=$(id -g roboshop)
    sed -i -e "/uid/ c uid = $USER_ID"  -e "/gid/ c gid = $GROUP_ID" $COMPONENT.ini
    stat $? 

    # Calling Configure Service
    CONFIG_SERVICE

    # Calling Configure Service
    START_SERVICE

}

MAVEN(){
    echo -n "Installing maven: "
    yum install maven -y &>> $LOGFILE 
    stat $? 

    #Calling user creation function
    CREATE_USER

    # Calling Function 
    DOWNLOAD_AND_EXTRACT 

    echo -n "Packaging the $COMPONENT Artifact: "
    mvn clean package  &>> $LOGFILE  &&  mv target/$COMPONENT-1.0.jar $COMPONENT.jar
    stat $?

    # Calling Configure Service
    CONFIG_SERVICE

    # Calling Configure Service
    START_SERVICE

}

NODEJS() {
    echo -n "Configuring NodeJS Repo: "
    curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>> $LOGFILE
    stat $? 

    echo -n "Installing NodeJS: "
    yum install nodejs -y &>> $LOGFILE 
    stat $? 
    
    #Calling user creation function
    CREATE_USER

    # Calling Function 
    DOWNLOAD_AND_EXTRACT

    echo -n "Installing $COMPONENT: "
    npm install  &>> $LOGFILE
    stat $? 

    # Calling Configure Service
    CONFIG_SERVICE

    # Calling Configure Service
    START_SERVICE
}

CREATE_USER() {
    echo -n "Creating the roboshop user: "
    id roboshop &>> $LOGFILE || useradd roboshop 
    stat $? 
}

DOWNLOAD_AND_EXTRACT() {
    echo -n "Downloading $COMPONENT repo: "
    curl -s -L -o /tmp/${COMPONENT}.zip "https://github.com/stans-robot-project/${COMPONENT}/archive/main.zip"
    stat $? 

    echo -n "Performing cleanup: "
    cd /home/roboshop/ && rm -rf ${COMPONENT}  &>> $LOGFILE 
    stat $?

    echo -n "Extracting $COMPONENT: "
    cd /home/roboshop
    unzip -o /tmp/${COMPONENT}.zip  &>> $LOGFILE 
    mv ${COMPONENT}-main ${COMPONENT}  &&  chown -R $APPUSER:$APPUSER $COMPONENT 
    cd ${COMPONENT}
    stat $?
}

CONFIG_SERVICE() {
    echo -n "Configuring $COMPONENT service: "
    sed -i -e 's/AMQPHOST/rabbitmq.roboshop.internal/' -e 's/USERHOST/user.roboshop.internal/' -e 's/CARTHOST/cart.roboshop.internal/' -e 's/DBHOST/mysql.roboshop.internal/' -e 's/CARTENDPOINT/cart.roboshop.internal/' -e 's/CATALOGUE_ENDPOINT/catalogue.roboshop.internal/' -e 's/REDIS_ENDPOINT/redis.roboshop.internal/' -e 's/REDIS_ENDPOINT/redis.roboshop.internal/'  -e 's/MONGO_ENDPOINT/mongodb.roboshop.internal/' -e 's/MONGO_DNSNAME/mongodb.roboshop.internal/' systemd.service
    mv /home/$APPUSER/$COMPONENT/systemd.service  /etc/systemd/system/$COMPONENT.service
    stat $? 
}

START_SERVICE() {
    echo -n "Starting $COMPONENT service: "
    systemctl daemon-reload 
    systemctl restart $COMPONENT 
    systemctl enable $COMPONENT  &>> $LOGFILE  
    systemctl status $COMPONENT -l &>> $LOGFILE 
    stat $?     
}