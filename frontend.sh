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

mkdir -p $LOGS_FLODER

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? "Removing old version of code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading new version of code"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? "UnZipping the new version of code in html"

cp /home/ec2-user/expense-shellscript/expense.conf /etc/nginx/default.d/expense.conf

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"
