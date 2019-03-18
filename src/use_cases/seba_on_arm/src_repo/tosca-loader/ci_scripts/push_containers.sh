export IMAGE_TAG=$(cat VERSION)
export AARCH=`uname -m`
docker build -t cachengo/xos-tosca-$AARCH:$IMAGE_TAG .
docker push cachengo/xos-tosca-$AARCH:$IMAGE_TAG
cd loader
docker build -f Dockerfile.tosca-loader -t cachengo/tosca-loader-$AARCH:$IMAGE_TAG .
docker push cachengo/tosca-loader-$AARCH:$IMAGE_TAG
