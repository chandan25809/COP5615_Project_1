#!/bin/bash

# Check min required arguments
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <executable> <arg1> <arg2> ... <argN>"
  exit 1
fi

filePath="$1"
shift 

# Check if the file exists or not
if [ ! -f "$filePath" ]; then
  echo "File not found: $filePath"
  exit 1
fi

/usr/bin/time -p "$filePath" "$@" 2> time_output.txt

# Get real, user, and system times from the time_output.txt file
real_time=$(grep 'real' time_output.txt | awk '{print $2}')
user_time=$(grep 'user' time_output.txt | awk '{print $2}')
sys_time=$(grep 'sys' time_output.txt | awk '{print $2}')

# Total CPU time (user time + system time)
cpu_time=$(echo "$user_time + $sys_time" | bc)

# Exit if real yime si too small to measure
if (( $(echo "$real_time < 0.01" | bc -l) )); then
  echo "Real Time too small to measure. Cores used: N/A"
  exit 0
fi

# Calculate the ratio of CPU time to real time
cpu_real_ratio=$(echo "scale=2; $cpu_time / $real_time" | bc -l)

# Number of available CPU cores
num_cores=$(sysctl -n hw.logicalcpu)  # macOS


if (( $(echo "$cpu_real_ratio < 1.00" | bc -l) )); then
  echo "Parallelism is very low (CPU time is close to Real time)"
elif (( $(echo "$cpu_real_ratio > $num_cores" | bc -l) )); then
  echo "Exceeded the number of available cores"
else
  effective_cores=$(echo "$cpu_real_ratio" | awk '{printf "%d", $1}')
  echo "parallelism with approximately $effective_cores cores"
fi

echo "Real Time: $real_time seconds"
echo "User Time: $user_time seconds"
echo "System Time: $sys_time seconds"
echo "CPU Time: $cpu_time seconds"
echo "CPU Time to Real Time Ratio: $cpu_real_ratio"
echo "Available cores: $num_cores"

