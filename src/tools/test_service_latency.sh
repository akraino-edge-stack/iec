set -e

localIP=$(ip route show default | cut -d " " -f 9)
echo "localIP:"$localIP

if [ "x${1}" == "x" ]; then
echo "No node IP defined, uses the local IP instead."
fi

nodeIP=$localIP
aNum=1000


display_help () {
  echo "Usage:"
  echo " "
  echo "Please input the nodeIP and access number"
}

#svcIP=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $3}')
#echo "Service IP:"$svcIP
#nodePort=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $5}' | cut -d ":" -f 2 |cut -d "/" -f 1)
#echo "NodePort:"$nodePort


ARGS=`getopt -a -o s:n:c:p:k::h:: -l nodeIP:,number:,serviceIP:,nodePort:,nodeOnly::,help:: -- "$@"`
eval set -- "${ARGS}"
while true
do
        case "$1" in
        -s|--nodeIP)
                nodeIP="$2"
                echo "nodeIP=$2"
                shift
                ;;
        -n|--number)
                aNum="$2"
                echo "access number=$2"
                shift
                ;;
        -c|--serviceIP)
                svcIP="$2"
		echo "Service IP=$2"
                shift
                ;;
        -p|--nodePort)
                nodePort="$2"
		echo "nodePort=$2"
                shift
                ;;
        -k|--nodeOnly)
                nodeOnly="true"
                echo "Ignore accessing service IP test."
		echo "nodeOnly=true"
                ;;
        -h|--help)
                echo "this is help case"
                display_help
                exit 0
                ;;
        --)
		echo ""
                echo "Use default args, now do the test:"
		echo ""
                shift
                break
                ;;
        esac
shift
done


if [[ "x${svcIP}" == "x"  &&  ${onlyNode} != "true" ]]; then
  echo "No service IP defined, try to find locally:"
  svcIP=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $3}')
  echo "Service IP:"$svcIP
fi

if [ "x${nodePort}" == "x" ]; then
  echo "No nodePort defined, try to find locally:"
  nodePort=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $5}' | cut -d ":" -f 2 |cut -d "/" -f 1)
  echo "NodePort:"$nodePort
fi


accessNum=$((aNum + 0))
#for i in {1..$(($aNum + 0))} 
START=1
END=$aNum


if [ "x${nodeOnly}" != "xtrue" ]; then
  echo "Now access the service IP $svcIP:80, $aNum times:"
  for (( c=$START; c<=$END; c++))
  do 
    curl -w "%{time_total}\n" -o /dev/null -s http://$svcIP
  done | jq -s add/length
fi

echo ""
echo "Now access the $nodeIP:$nodePort, $aNum times"
for (( c=$START; c<=$END; c++))
do
    curl -w "%{time_total}\n" -o /dev/null -s $nodeIP:$nodePort
done | jq -s add/length
