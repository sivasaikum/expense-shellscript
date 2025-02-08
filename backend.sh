#!/bin/bash


USERID=$( id -u )

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FLODER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FLODER/$LOG_FILE-$TIMESTAMP"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT() {
   if [ $USERID -ne 0 ]
    then
    echo "ERROR :: you must have a root access to execute this script"
    exit 1
    fi 
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y
VALIDATE $? "Disabling default nodejs version"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling new nodejs version : 20 "

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

useradd expense
VALIDATE $? "Expense user is created"

mkdir /app
VALIDATE $? "Creating App Directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading App code to App Directory"

cd /app
unzip /tmp/backend.zip
VALIDATE $? "UnZiping the backend application"

cd /app
npm install
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shellscript/backend.service /etc/systemd/system/backend.service

dnf install mysql -y
VALIDATE $? "Installing Mysql Client"

mysql -h mysql.jobsearchindia.online -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Loading Transactions Schema"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable backend
VALIDATE $? "Enabling backend"

systemctl restart backend
VALIDATE $? "Restarting Backend"

