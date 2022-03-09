#!/bin/bash

MEMORY_AVAIL=`free -m | grep Mem | awk '{print $7}'`

echo "Tööriista paigaldus"
START_TIME=$SECONDS
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/bin/kind

echo "Tööriista paigaldus võttis $(($SECONDS - $START_TIME)) sekundit"


echo "Tööriistaga klastri loomine."
START_TIME=$SECONDS
free -m
kind create cluster --config run_kind.yaml
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


#kind delete cluster --name multi-a
