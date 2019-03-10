green=`tput setaf 2`
reset=`tput sgr0`

run_cmd() {
        cmd="$1";
        echo -e "\n\n >> ${green} Next command: $1 \n\n ${reset}";
        #wait;
        #read -p "Press enter to continue ${reset}";
        eval "cleos --wallet-url $WALLET_URL -u $API_URL $1";
}

create_act() {
  creator="$1"
  act="$2"
  key="$3"
  eval "cleos --wallet-url $WALLET_URL -u $API_URL system newaccount --stake-cpu \"5.0000 EOS\" --stake-net \"1.0000 EOS\" --transfer --buy-ram-kbytes 1025 $creator $act $key"
}