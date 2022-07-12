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

ARGS=`getopt -a -o s:n:h -l nodeIP:,number:,help -- "$@"`
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
        -h|--help)
                echo "this is help case"
                display_help
                ;;
        --)
                echo "Now do the test:"
                shift
                break
                ;;
        esac
shift
done


svcIP=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $3}')
echo "Service IP:"$svcIP
nodePort=$(kubectl get svc | grep nginx |grep -i "nodeport" | awk -F'[ ]+' '{print $5}' | cut -d ":" -f 2 |cut -d "/" -f 1)
echo "NodePort:"$nodePort

accessNum=$((aNum + 0))
echo "Now access the service IP, $aNum times:"
#for i in {1..$(($aNum + 0))} 
START=1
END=$aNum

for (( c=$START; c<=$END; c++))
do 
    curl -w "%{time_total}\n" -o /dev/null -s http://$svcIP
done | jq -s add/length

echo "Now access the NodePort, $aNum times"
for (( c=$START; c<=$END; c++))
do
    #curl -w "%{time_total}\n" -o /dev/null -s http://10.169.210.208:31942 
    #curl -w "%{time_total}\n" -o /dev/null -s http://10.169.210.208:31942 
    curl -w "%{time_total}\n" -o /dev/null -s $localIP:$nodePort
done | jq -s add/length
