#!/bin/bash

set -e

accessNum=$((aNum + 0))
START=1
END=5

urlIP=${1:-172.26.12.101}
urlPort=${2:-30942}
 

IFS_OLD=$IFS
IFS=$'\n'


runCmd(){

for (( c=$START; c<=$END; c++))
do
    
    #curl -w "%{time_total}\n" -o /dev/null -s http://$svcIP
    cmd=$1
    echo "Round:"$c"--"$cmd
    output=$(eval $cmd)
    #echo $output
    for line in  $output
    do
      #echo "${line}"
      result=$(echo ${line} | grep "Latency") || true
      #echo $result
      if [ "aaa${result}" != "aaa" ]; then
	 latency[$c]=$(echo $result | awk '{print $2}')
      fi
      sleep 0.1
      result=$(echo ${line} | grep "Requests/sec") || true
      if [ "aaa${result}" != "aaa" ]; then
	 requests[$c]=$(echo $result | awk '{print $2}')
      fi
      sleep 0.1
      result=$(echo ${line} | grep "Transfer/sec") || true
      if [ "aaa${result}" != "aaa" ]; then
	 transfer[$c]=$(echo $result | awk '{print $2}')
      fi
      sleep 0.1
    done

done 

echo "Latency:"
for (( c=$START; c<=$END; c++))
do
   echo ${latency[$c]}
done


echo "requests/sec:"
for (( c=$START; c<=$END; c++))
do
   echo ${requests[$c]}
done


echo "Transfer/sec:"
for (( c=$START; c<=$END; c++))
do
   echo ${transfer[$c]}
done

}

runCmd "/usr/bin/wrk -t12 -c400 -d30s http://${urlIP}:${urlPort}"
runCmd "/usr/bin/wrk -t12 -c400 -d30s http://${urlIP}:${urlPort}/files/file-100K"
runCmd "/usr/bin/wrk -t12 -c400 -d30s http://${urlIP}:${urlPort}/files/file-1M"

IFS=$IFS_OLD
