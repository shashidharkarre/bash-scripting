#!/bin/bash
set -e 
COMPONENT=shipping 
LOGFILE="/tmp/$COMPONENT.log"
APPUSER="roboshop"

source components/common.sh

# Calling MAVEN Function
MAVEN

echo -e " ____________________ \e[32m $COMPONENT Configuration is completed ____________________ \e[0m"
