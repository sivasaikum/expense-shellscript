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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling default nodejs version"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling new nodejs version : 20 "

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

# id expense &>>$LOG_FILE_NAME

# if [ $? -ne 0 ]
# then
#     useradd expense &>>$LOG_FILE_NAME
#     VALIDATE $? "Creating Expense user"
# else
#     echo -e "expense user is alredy $Y EXISTS $N"
# fi


id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user already exists ... $Y SKIPPING $N"
fi


mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating App Directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading App code to App Directory"

cd /app
unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "UnZiping the backend application"

cd /app
npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shellscript/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Mysql Client"

mysql -h mysql.jobsearchindia.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Loading Transactions Schema"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restarting Backend"

