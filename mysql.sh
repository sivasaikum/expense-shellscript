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

# dnf list installed mysql-server &>>$LOG_FILE_NAME

# if [ $? -ne 0 ]
# then
#     dnf install mysql-server -y &>>$LOG_FILE_NAME
#     VALIDATE $? "mysql server installing"
    
# else
#     echo -e "MYSQL is already ... $G INSTALLED $N "
# fi

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "mysql server installing"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling mysqld server"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysqld server"

mysql -h mysql.jobsearchindia.online -u root -pExpenseApp@1 -e "show databases;" &>>$LOG_FILE_NAME

if [ $? -ne 0]
then
    mysql_secure_installation --set-root-pass ExpenseApp@1 
    VALIDATE $? "Setting Root Password"
else
    echo -e "Root password is already $Y completed $N"
fi