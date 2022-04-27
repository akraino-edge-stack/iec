#!/bin/bash

INSTANCE_NUM=4
ROBOX_TEMPLATE_YAML=$(cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: anbox
spec:
  selector:
    matchLabels:
      app: android
  replicas: 1
  template:
    metadata:
      labels:
        app: android
    spec:
      containers:
      - name: android
        image: android:robox
        resources:
          requests:
            cpu: 1
            memory: 1024Mi
          limits:
            cpu: 4
            memory: 4096Mi
        env:
        - name: ANDROID_NAME
          value: "xbox"
        - name: PATH
          value: "/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin"
        - name: ANDROID_ROOT
          value: "/"
        - name: ANDROID_DATA
          value: "/data"
        - name: DOWNLOAD_CACHE
          value: "/data/cache"
        - name: LOGNAME
          value: "shell"
        - name: HOME
          value: "/"
        - name: TERM
          value: "screen-256color"
        - name: SHELL
          value: "/system/bin/sh"
        - name: ANDROID_BOOTLOGO
          value: "1"
        - name: TMPDIR
          value: "/data/local/tmp"
        - name: ANDROID_ASSETS
          value: "/system/app"
        - name: BOOTCLASSPATH
          value: "/system/framework/core-oj.jar:/system/framework/core-libart.jar:/system/framework/conscrypt.jar:/system/framework/okhttp.jar:/system/framework/core-junit.jar:/system/framework/bouncycastle.jar:/system/framework/ext.jar:/system/framework/framework.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/apache-xml.jar:/system/framework/org.apache.http.legacy.boot.jar"
        - name: ASEC_MOUNTPOINT
          value: "/mnt/asec"
        - name: ANDROID_SOCKET_adbd
          value: "7"
        - name: HOSTNAME
          value: "arm64"
        - name: EXTERNAL_STORAGE
          value: "/sdcard"
        - name: ANDROID_STORAGE
          value: "/storage"
        - name: USER
          value: "shell"
        - name: SYSTEMSERVERCLASSPATH
          value: "/system/framework/services.jar:/system/framework/ethernet-service.jar:/system/framework/wifi-service.jar"
        imagePullPolicy: Never
        command: ["/system/bin/sh", "-ce", "/anbox-init.sh"]
        ports:
        - containerPort: 5555
        securityContext:
          privileged: true
          #capabilities:
          #  add: [ "SYS_ADMIN", "NET_ADMIN", "SYS_MODULE", "SYS_NICE", "SYS_TIME", "SYS_TTY_CONFIG", "NET_BROADCAST", "IPC_LOCK", "SYS_RESOURCE" ]
        volumeMounts:
        - mountPath: /dev/binder:rw
          name: volume-binder
        - mountPath: /dev/ashmem:rw
          name: volume-ashmem
        - mountPath: /dev/fuse:rw
          name: volume-fuse
        - mountPath: /dev/qemu_pipe
          name: volume-qemupipe
        - mountPath: /dev/anbox_audio:rw
          name: volume-anboxaudio
        - mountPath: /dev/anbox_bridge:rw
          name: volume-anboxbridge
        - mountPath: /dev/input/event0:rw
          name: volume-event0
        - mountPath: /dev/input/event1:rw
          name: volume-event1
        - mountPath: /cache:rw
          name: volume-cache
        - mountPath: /data:rw
          name: volume-data
      volumes:
      - name: volume-binder
        hostPath:
          path: /dev/binder${INSTANCE_NUM}
      - name: volume-ashmem
        hostPath:
          path: /dev/ashmem
      - name: volume-fuse
        hostPath:
          path: /dev/fuse
      - name: volume-qemupipe
        hostPath:
          path: /run/user/1000/anbox/${INSTANCE_NUM}/sockets/qemu_pipe
      - name: volume-anboxaudio
        hostPath:
          path: /run/user/1000/anbox/${INSTANCE_NUM}/sockets/anbox_audio
      - name: volume-anboxbridge
        hostPath:
          path: /run/user/1000/anbox/${INSTANCE_NUM}/sockets/anbox_bridge
      - name: volume-event0
        hostPath:
          path: /run/user/1000/anbox/${INSTANCE_NUM}/input/event0
      - name: volume-event1
        hostPath:
          path: /run/user/1000/anbox/${INSTANCE_NUM}/input/event1
      - name: volume-cache
        hostPath:
          path: /home/robox/anbox-data/${INSTANCE_NUM}/cache
      - name: volume-data
        hostPath:
          path: /home/robox/anbox-data/${INSTANCE_NUM}/data
---
apiVersion: v1
kind: Service
metadata:
  name: anbox
spec:
  selector:
    app: android
  ports:
  - protocol: TCP
    port: 8888
    targetPort: 5555
    nodePort: 31000
  type: NodePort
EOF
)

if [ "$1" = "a" ]; then
echo "$ROBOX_TEMPLATE_YAML" | kubectl apply -f - > /dev/null
else
echo "$ROBOX_TEMPLATE_YAML" | kubectl delete -f - > /dev/null
fi
echo $?
sleep 2
watch -n 1 kubectl get node,pods,svc -o wide -n kube-system -n default
