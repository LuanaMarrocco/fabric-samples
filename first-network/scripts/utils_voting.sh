# import utils
. scripts/utils.sh

CC_SRC_PATH_VOTING="github.com/chaincode/voting/go/"
CHANNEL_NAME="mychannel"
CC_NAME="myccVoting"

setUpVoting(){
  install $1 $2
  instantiate $1 $2
}


install(){
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.0}
  set -x
  peer chaincode install -n $CC_NAME -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH_VOTING}>&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode Voting installation on peer${PEER}.org${ORG} has failed"
  echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
  echo
}

instantiate(){
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  VERSION=${3:-1.0}

  # while 'peer chaincode' command can get the orderer endpoint from the peer
  # (if join was successful), let's supply it directly as we know it using
  # the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n $CC_NAME -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')" >&log.txt
    res=$?
    set +x
  else
    set -x
      peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C  $CHANNEL_NAME -n $CC_NAME -l ${LANGUAGE} -v 1.0 -c '{"Args":[]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')" >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode is instantiated on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

testVoting(){
  peer chaincode invoke -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} $PEER_CONN_PARMS -c '{"Args":["init","314"]}'
  peer chaincode invoke -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C mychannel -n ${CC_NAME} -c '{"Args":["init_voter","v001","100"]}'
  peer chaincode query -C mychannel -n ${CC_NAME} -c '{"Args":["read_voter","v001"]}'
}

