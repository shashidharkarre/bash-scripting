#!/bin/bash

set -e 
COMPONENT=frontend 
LOGFILE="/tmp/$COMPONENT.log"

source components/common.sh

echo -n "Installing Nginx: "
yum install nginx -y &>> $LOGFILE
stat $?


systemctl enable nginx &>> $LOGFILE 

echo -n "Downloading $COMPONENT: "
curl -s -L -o /tmp/frontend.zip "https://github.com/stans-robot-project/frontend/archive/main.zip"
stat $? 

echo -n "Clearing the old content: "
cd /usr/share/nginx/html
rm -rf *
stat $? 

echo -n "Extracting the $COMPONENT: "
unzip /tmp/frontend.zip &>> $LOGFILE
stat $? 

echo -n "Updating the PROXY file: "
mv frontend-main/* .
mv static/* .
rm -rf frontend-main README.md
mv localhost.conf /etc/nginx/default.d/roboshop.conf
stat $? 

echo -n "Configuring the proxy file: "
sed -i  -e '/payment/s/localhost/payment.roboshop.internal/' -e '/shipping/s/localhost/shipping.roboshop.internal/' -e '/user/s/localhost/user.roboshop.internal/' -e '/cart/s/localhost/cart.roboshop.internal/' -e '/catalogue/s/localhost/catalogue.roboshop.internal/' /etc/nginx/default.d/roboshop.conf
stat $? 

echo -n "Retarting Nginx: "
systemctl restart nginx
stat $?

echo -e " ____________________ \e[32m $COMPONENT Configuration is completed ____________________ \e[0m"