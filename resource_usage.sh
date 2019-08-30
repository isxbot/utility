#!/bin/bash

# Capture CPU and memory usage every 30 seconds, and export to CSV log file.
# Used code from https://shreve.io/posts/calculating-current-cpu-usage-on-linux to calculate CPU usage.

EPOCH=$(date +%s)

# Store log on root. Append epoch to file name to keep previous runs from being overwritten.
LOG="/${HOSTNAME}_resource_usage_${EPOCH}.csv"
echo -e "Starting CPU and Memory utilization log at $(date +"%Y-%m-%d %H:%M:%S")\n"
echo "time,cpu_utilization_%,memory_utilization_%" >> $LOG

# Remove trailing return on exit.
trap "truncate -s -1 $LOG" EXIT

# Function to save CPU state to /tmp
cpustat(){
  grep 'cpu ' /proc/stat > /tmp/cpustat
}

# Save current state to a /tmp file
[ ! -e /tmp/cpustat ] && cpustat

awkscript='NR==1 {
            owork=($2+$4);
            oidle=$5;
          }
          NR > 1 {
            work=($2+$4)-owork;
            idle=$5-oidle;
            printf (100 * work / (work+idle))
          }'

while true; do

  # Get seconds position.
  pos=$(date +%S)

  # Take measurements twice per minute.
  if [[ $pos == 00 || $pos == 30 ]] ; then

    # Get and write time.
    time=$(date +"%Y-%m-%d %H:%M:%S")
    echo -n "$time," >> $LOG

    previous=$(cat /tmp/cpustat)
    current=$(grep 'cpu ' /proc/stat)
    
    # Calcualte current usage.
    cpusage=$(echo -e "$previous\n$current" | awk "$awkscript")
    
    # Update /tmp/cpustat
    cpustat
    
    echo -n "$cpusage," >> $LOG

    # Get memory usage from free, calculate usage.
    memusage=$(free | awk 'FNR==2{ usage=($3/$2)*100 ; print usage}')
    echo -en "$memusage\n" >> $LOG

    # Update stdout with most recent measurement.
    echo -e "Logging CPU and Memory usage.\n$time\nCPU utilization: $cpusage%\nMemory utilization: $memusage%\n"
    sleep 5
  fi

done
