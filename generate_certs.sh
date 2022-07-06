#!/bin/bash

# Root CA
kubectl get secret "${SECRET_NAME:-"opensearch"}-root-cacerts" -n "${NAMESPACE:-"opensearch"}" > std 2>&1
if [ $? -eq 1 ]; then
    echo "Creating root CA"
    certstrap init --common-name "root-ca" --expires "${EXPIRATION:-"5 years"}" --organization "${ORGANIZATION:-"Giant Swarm"}" --passphrase ""

    kubectl create secret generic "${SECRET_NAME:-"opensearch"}-root-cacerts" -n "${NAMESPACE:-"opensearch"}" \
        --from-file=root-ca.crl=./out/root-ca.crl \
        --from-file=root-ca.crt=./out/root-ca.crt \
        --from-file=root-ca.key=./out/root-ca.key
else
    echo "Root CA already exists"
    mkdir out
    kubectl get secrets "${SECRET_NAME:-"opensearch"}-root-cacerts" -o jsonpath="{.data.root-ca\.crl}" | base64 --decode > ./out/root-ca.crl
    kubectl get secrets "${SECRET_NAME:-"opensearch"}-root-cacerts" -o jsonpath="{.data.root-ca\.crt}" | base64 --decode > ./out/root-ca.crt
    kubectl get secrets "${SECRET_NAME:-"opensearch"}-root-cacerts" -o jsonpath="{.data.root-ca\.key}" | base64 --decode > ./out/root-ca.key
fi

# Opensearch transport Certs
kubectl get secret "${SECRET_NAME:-"opensearch"}-transport-certs" -n "${NAMESPACE:-"opensearch"}" > std 2>&1
if [ $? -eq 1 ]; then
    echo "Creating transport certificates"
    certstrap request-cert --common-name "transport" --organization "${ORGANIZATION:-"Giant Swarm"}" --passphrase ""
    certstrap sign transport --CA "root-ca" --expires "${EXPIRATION:-"5 years"}"
    openssl pkcs8 -v1 "PBE-SHA1-3DES" -in ./out/transport.key -topk8 -out ./out/transport.pem -nocrypt

    kubectl create secret generic "${SECRET_NAME:-"opensearch"}-transport-certs" -n "${NAMESPACE:-"opensearch"}" \
        --from-file=transport-crt.pem=./out/transport.crt \
        --from-file=transport-key.pem=./out/transport.pem \
        --from-file=transport-root-ca.pem=./out/root-ca.crt

    echo "Deleting pods with label ${RELEASE:-"opensearch"}"
    kubectl delete pods -l release="${RELEASE:-"opensearch"}"
else
    echo "Transport certificates already exist"
fi

# Opensearch rest api Certs
kubectl get secret "${SECRET_NAME:-"opensearch"}-restapi-certs" -n "${NAMESPACE:-"opensearch"}" > std 2>&1
if [ $? -eq 1 ]; then
    echo "Creating restapi certificates"
    certstrap request-cert --common-name "restapi" --organization "${ORGANIZATION:-"Giant Swarm"}" --passphrase ""
    certstrap sign restapi --CA "root-ca" --expires "${EXPIRATION:-"5 years"}"
    openssl pkcs8 -v1 "PBE-SHA1-3DES" -in ./out/restapi.key -topk8 -out ./out/restapi.pem -nocrypt

    kubectl create secret generic "${SECRET_NAME:-"opensearch"}-restapi-certs" -n "${NAMESPACE:-"opensearch"}" \
        --from-file=restapi-crt.pem=./out/restapi.crt \
        --from-file=restapi-key.pem=./out/restapi.pem \
        --from-file=restapi-root-ca.pem=./out/root-ca.crt

    echo "Deleting pods with label ${RELEASE:-"opensearch"}"
    kubectl delete pods -l release="${RELEASE:-"opensearch"}"
else
    echo "restapi certificates already exist"
fi

# Opensearch dashboards Certs
kubectl get secret "${SECRET_NAME:-"opensearch"}-dashboards-certs" -n "${NAMESPACE:-"opensearch"}" > std 2>&1
if [ $? -eq 1 ]; then
    echo "Creating restapi certificates"
    certstrap request-cert --common-name "dashboards" --organization "${ORGANIZATION:-"Giant Swarm"}" --passphrase ""
    certstrap sign dashboards --CA "root-ca" --expires "${EXPIRATION:-"5 years"}"
    openssl pkcs8 -v1 "PBE-SHA1-3DES" -in ./out/dashboards.key -topk8 -out ./out/dashboards.pem -nocrypt

    kubectl create secret generic "${SECRET_NAME:-"opensearch"}-dashboards-certs" -n "${NAMESPACE:-"opensearch"}" \
        --from-file=dashboards-crt.pem=./out/dashboards.crt \
        --from-file=dashboards-key.pem=./out/dashboards.pem \
        --from-file=dashboards-root-ca.pem=./out/root-ca.crt

    echo "Deleting pods with label ${RELEASE:-"opensearch"}"
    kubectl delete pods -l release="${RELEASE:-"opensearch"}"
else
    echo "dashboards certificates already exist"
fi

exit $?