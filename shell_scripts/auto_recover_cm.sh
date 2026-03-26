#!/bin/bash

# Load environment
source ../config/env.sh

DATE=$(date +%Y%m%d_%H%M)
LOG_FILE=$LOG_DIR/cm_recovery_$DATE.log

echo "====================================" >> $LOG_FILE
echo "Concurrent Manager Auto Recovery" >> $LOG_FILE
echo "Start Time: $DATE" >> $LOG_FILE
echo "====================================" >> $LOG_FILE

# Function to check ICM
ICM_STATUS=$(sqlplus -s $DB_USER/$DB_PASS <<EOF
SET HEAD OFF FEED OFF
SELECT running_processes
FROM fnd_concurrent_queues
WHERE concurrent_queue_name='Internal Manager';
EXIT;
EOF
)

echo "ICM Running Processes: $ICM_STATUS" >> $LOG_FILE

# Function to check Standard Manager
STD_STATUS=$(sqlplus -s $DB_USER/$DB_PASS <<EOF
SET HEAD OFF FEED OFF
SELECT running_processes
FROM fnd_concurrent_queues
WHERE concurrent_queue_name='Standard Manager';
EXIT;
EOF
)

echo "Standard Manager Processes: $STD_STATUS" >> $LOG_FILE

# Condition: If ICM is down OR Standard Manager is 0
if [[ "$ICM_STATUS" -eq 0 || "$STD_STATUS" -eq 0 ]]
then
  echo "⚠️ Issue detected: Restarting Concurrent Managers..." >> $LOG_FILE

  cd $ADMIN_SCRIPTS_HOME

  ./adcmctl.sh stop $DB_USER/$DB_PASS >> $LOG_FILE
  sleep 10
  ./adcmctl.sh start $DB_USER/$DB_PASS >> $LOG_FILE

  echo "✅ Concurrent Managers Restarted" >> $LOG_FILE
else
  echo "✅ All Concurrent Managers are running fine" >> $LOG_FILE
fi

echo "End Time: $(date)" >> $LOG_FILE
echo "====================================" >> $LOG_FILE
