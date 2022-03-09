#!/bin/bash

MEMORY_AVAIL=`free -m | grep Mem | awk '{print $7}'`

echo "Tööriista paigaldus"
START_TIME=$SECONDS
sudo snap install lxd
sudo lxd init
lxc profile create microk8s
wget https://raw.githubusercontent.com/ubuntu/microk8s/master/tests/lxc/microk8s.profile -O microk8s.profile
cat microk8s.profile | lxc profile edit microk8s
rm microk8s.profile

echo "Tööriista paigaldus võttis $(($SECONDS - $START_TIME)) sekundit"


echo "Tööriistaga klastri loomine."
START_TIME=$SECONDS
free -m
#https://microk8s.io/docs/lxd
#https://ubuntu.com/tutorials/getting-started-with-kubernetes-ha?&_ga=2.199186223.1894255953.1646810874-1723796373.1646050010#4-create-a-microk8s-multinode-cluster

lxc launch -p default -p microk8s-m1 ubuntu:20.04 microk8s
lxc exec microk8s -- sudo snap install microk8s --classic
lxc shell microk8s "cat > /etc/rc.local <<EOF
#!/bin/bash
apparmor_parser --replace /var/lib/snapd/apparmor/profiles/snap.microk8s.*
exit 0
EOF"
lxc exec microk8s -- sudo chmod +x /etc/rc.local

microk8s status --wait-ready

echo "Tööriista käivitamine võttis $(($SECONDS - $START_TIME)) sekundit"

echo "Kontroll kas kõik töötaja masinad on valmis."
START_TIME=$SECONDS
foo="1"
while [ "$foo" -lt "8" ]
do
        sleep 1
        foo=$(microk8s kubectl get nodes | grep Ready | wc -l)
        echo "$foo nodes ready, waiting."
done
microk8s kubectl get nodes
echo "Kõik töötaja masinad on valmis $(($SECONDS - $START_TIME)) sekundiga."

MEM_NOW=`free -m | grep Mem | awk '{print $7}'`

echo "Mälukasutuse muutus on $(($MEMORY_AVAIL - $MEM_NOW))"
free -m

yo

