#!/bin/bash
TODAY=$(date +"%d-%m-%Y")
COGNIGY_AI_NAMESPACE=cognigy-ai
LIVE_AGENT_ENABLED=false
LIVE_AGENT_NAMESPACE=live-agent

TARGET_DIR="secrets-backup-${TODAY}"
if [ -d ${TARGET_DIR} ]
then
  echo "target Directory ${TARGET_DIR} already exists, exiting now..."
  exit 0;
fi
echo "Creating Target directory ${TARGET_DIR}"
mkdir ./${TARGET_DIR}
mkdir ./${TARGET_DIR}/cognigy-ai
echo "Backup secrets of Cognigy.AI within ${COGNIGY_AI_NAMESPACE} namespace"
kubectl -n ${COGNIGY_AI_NAMESPACE} get --no-headers secrets --field-selector type=Opaque | awk '/cognigy/{print $1}' | xargs -I {} sh -c "kubectl -n ${COGNIGY_AI_NAMESPACE} get secret {} -o yaml  > ./${TARGET_DIR}/cognigy-ai/{}.yaml"
if [ ${LIVE_AGENT_ENABLED} = true ]
then
  mkdir ./${TARGET_DIR}/cognigy-live-agent
  echo "Backup secrets of Live-Agent within ${LIVE_AGENT_NAMESPACE} namespace"
  kubectl -n ${LIVE_AGENT_NAMESPACE} get --no-headers secrets --field-selector type=Opaque | awk '{print $1}' | xargs -I {} sh -c "kubectl -n ${LIVE_AGENT_NAMESPACE} get secret {} -o yaml  > ./${TARGET_DIR}/cognigy-live-agent/{}.yaml"
fi
echo "Backup is done. Please store the backup folder somewhere securely since it contains Passwords"