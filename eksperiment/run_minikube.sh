#!/bin/bash

MEMORY_AVAIL=`free -m | grep Mem | awk '{print $7}'`

echo "Tööriista paigaldus"
START_TIME=$SECONDS
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/bin/minikube

echo "Tööriista paigaldus võttis $(($SECONDS - $START_TIME)) sekundit"


echo "Tööriistaga klastri loomine."
START_TIME=$SECONDS
free -m
minikube start -n 6 --container-runtime docker --driver=docker 
minikube node add --control-plane=true
minikube node add --control-plane=true
echo "Tööriista käivitamine võttis $(($SECONDS - $START_TIME)) sekundit"

echo "Kontroll kas kõik töötaja masinad on valmis."
START_TIME=$SECONDS
foo="1"
while [ "$foo" -lt "8" ]
do
        sleep 1
        foo=$(kubectl get nodes | grep Ready | wc -l)
        echo "$foo nodes ready, waiting."
done
kubectl get nodes
echo "Kõik töötaja masinad on valmis $(($SECONDS - $START_TIME)) sekundiga."

MEM_NOW=`free -m | grep Mem | awk '{print $7}'`

echo "Mälukasutuse muutus on $(($MEMORY_AVAIL - $MEM_NOW))"
free -m

#minikube delete

