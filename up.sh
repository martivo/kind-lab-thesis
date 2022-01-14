#!/bin/bash

#Create kind kubernetes clusters
ls -1 kind-* | while read kindfile
do
  echo "Creating cluster from configuration file $kindfile"
  kind create cluster --config $kindfile
  break
done

#List kind clusters
kubectl config get-contexts | grep kind

#Argocd and sealed secret private key bootstrap
i=0
kind get clusters | while read cluster
do
echo "Initializing $cluster"
  kubectl --context kind-$cluster create ns argocd && \
  helm template argocd-yaml/argocd/ | kubectl --context kind-$cluster apply -n argocd -f- #https://argo-cd.readthedocs.io/en/stable/getting_started/ and https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/
  if [ -f sealed-secret-keys/${cluster}.yaml ]
  then
    echo "Loading sealed-secret private key from sealed-secret-keys/${cluster}.yaml"
    kubectl --context kind-$cluster apply -n kube-system -f sealed-secret-keys/${cluster}.yaml
  fi
  let i++
done

#Fetch argocd password and load app of apps.
i=0
kind get clusters | while read cluster
do
  echo "Waiting for argocd $cluster"
  while [ 1 -lt 2 ]
  do
	kubectl --context kind-$cluster -n argocd get secret argocd-initial-admin-secret && break
	sleep 10
  done
  echo "Argocd password"
  kubectl --context kind-$cluster -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  #docker network inspect -f '{{.IPAM.Config}}' kind
  helm template argocd-yaml/app-of-apps/ --set runenv="$cluster" --set internaldomain="int-$cluster.kind.learn.entigo.io" --set externaldomain="$cluster.kind.learn.entigo.io" --set iprange="10.250.1.2${i}0-10.250.1.2${i}9" | kubectl --context kind-$cluster apply -n argocd -f-

  let i++
  echo "##################"
done


#Dump SealedSecrets key in case this is a new cluster.
kind get clusters | while read cluster
do
  if [ ! -f sealed-secret-keys/${cluster}.yaml ]
  then
    echo "Waiting for sealed-secrets key $cluster"
    while [ 1 -lt 2 ]
    do  
	kubectl --context kind-$cluster get secrets -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key=active && break
        sleep 10
    done
    kubectl --context kind-$cluster get secrets  -l sealedsecrets.bitnami.com/sealed-secrets-key=active -n kube-system -o yaml | kubectl-neat  > sealed-secret-keys/${cluster}.yaml
    kubeseal --context kind-$cluster --fetch-cert > sealed-secret-keys/${cluster}.pub
  fi
done

exit 0


#kubeseal 
kubeseal --cert sealed-secret-keys/multi-a.pub --context kind-multi-a --format yaml  < certbot-secret-ext.yaml > argocd-yaml/sealed-secrets/multi-a/certbot-secret-ext.yaml

#Manual
https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md
Metallb dashboard 14127

#locust to prometheus and grafana
https://github.com/ContainerSolutions/locust_exporter

#We have 3 scenarios:
1) Statless application

2) Stateful application with redis(NOSQL)

3) Statless application with redis and mariadb(NOSQL, SQL)


With each scenario we will test following situations:
1) Loss of each node
2) Boched update.
3) Applicaiton level failure.(Application crashes)
4) Redis Database failure
5) Mariadb Database failure
6) Monitoring failure and detection
7) Logging failure and recovery

Compare what extra steps are needed in case of a multiple cluster installation and what might be the problematic areas.

#Acceptable issues
1) Non client facing services can be down for 1 hour.
2) Up to three requests can fail in a row before it is concidered failed.

