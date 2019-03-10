#!/bin/bash

source ./conf.sh
source ./functions.sh

prompt_color=`tput setaf 6`
reset=`tput sgr0`

# Set this to false if you don't want the script to prompt you for input and prefer to use configured values instead.
prompt_for_input=true

dacname="DAC Factory"
DAC_PVT="5KhYU7A4LNGmS6zu6Uf5z3AaDtzS7rojHPUZGQC2eMfiMm4PUWp" # all accounts created by this script will use this key
DAC_PUB="EOS5zQWu4DP6JuTgrp97LKS3vCws6aNS3RGbDUoAGgPqLHU69Boir" # all accounts created by this script will use this key
EOS_ACCOUNT="dacfactory11" # This is the account creating all the other DAC accounts. It should have at least 100 EOS.
daccustodian="dacfac11cust"
dacauthority="dacfac11auth"
dactoken="dacfac11tokn"
dacowner="dacfac11ownr"
dacservice="dacfac11serv"
dacmultisigs="dacfac11mult"
dacproposals="dacfac11prop"
TOKENSYBMOL="DACFAC"
DACTOKEN_COUNT_CREATE="1000000000"
DACTOKEN_COUNT_ISSUE="100000000"

echo "========================================================="
echo "=                                                       ="
echo "=              Welcome to the DAC Factory!              ="
echo "=                                                       ="
echo "=                 provided by eosDAC                    ="
echo "=                                                       ="
echo "========================================================="
echo " "
if [ prompt_for_input ]; then
  read -p " > ${prompt_color} What is the name of your DAC?${reset} " dacname
fi

if [[ "$dacname" == "" ]]; then
  exit
fi

echo "Thank you, $dacname"

read -p " > ${prompt_color} Have you already created an EOS account for your DAC (Y/N)?${reset} " response
if [[ "$response" == "Y" || "$response" == "y" ]]; then
  if [ prompt_for_input ]; then
    echo " > ${prompt_color} Please paste the private key:${reset} "
    read -s DAC_PVT
    read -p " > ${prompt_color} Please paste the public key:${reset} " DAC_PUB
    read -p " > ${prompt_color} Please paste the EOS account name:${reset} " EOS_ACCOUNT
  fi
else
  echo "Generating keys..."
  KEYS="$(cleos create key --to-console | awk '{ print $3 }')"
  DAC_PVT="$(echo $KEYS | head -n1 | awk '{print $1;}')"
  DAC_PUB="$(echo $KEYS | head -n1 | awk '{print $2;}')"
  read -p " > ${prompt_color} Are you ready to save your keys securely?:${reset} " response
  if [[ "$response" == "Y" || "$response" == "y" ]]; then
    echo "Private Key: $DAC_PVT"
    read -p " > ${prompt_color} Press any key to clear the screen and continue${reset}" response
    clear
    read -p " > ${prompt_color} Press verify your private key:${reset} " response
    if [[ $response != $DAC_PVT ]]; then
      echo "Private Key does not match!"
      exit
    fi
    read -p " > ${prompt_color} Press any key to clear the screen and continue${reset}" response
    clear
    read -p " > ${prompt_color} Press verify your public key:${reset} " response
    if [[ $response != $DAC_PUB ]]; then
      echo "Public Key does not match!"
      exit
    fi
    echo "Use the following key to create an account using the Jungle Testnet https://monitor.jungletestnet.io/#home."
    echo "Public Key: $DAC_PUB"
    echo "Be sure the account has at least 100 EOS which will be used for RAM, CPU, and Bandwidth. Do this using the faucet link."
    read -p " > ${prompt_color} Please paste the EOS account name you created:${reset} " EOS_ACCOUNT
  else
    exit
  fi
fi

run_cmd "get account $EOS_ACCOUNT"
if [ "$?" != "0" ]; then
  echo "The account you specified could not be found."
  exit
fi

if [ -f $EOS_ACCOUNT.wallet_password ]; then
  run_cmd "wallet unlock --name $EOS_ACCOUNT < $EOS_ACCOUNT.wallet_password"
else
  run_cmd "wallet create --file $EOS_ACCOUNT.wallet_password --name $EOS_ACCOUNT"
  run_cmd "wallet import --name $EOS_ACCOUNT --private-key $DAC_PVT"
fi

echo "Next we'll create EOS accounts (if they don't already exist) for your DAC. Use only letters and numbers 1-5. The account name needs to be exactly 12 characters."

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} The account holding the custodian (voting) contract (Custodian Account):${reset} " daccustodian
fi
run_cmd "get account $daccustodian" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $daccustodian $DAC_PUB
  else
    exit
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} An empty account used to represent various permission levels. All other DAC accounts will eventually point back to this (Authority Account):${reset} " dacauthority
fi
run_cmd "get account $dacauthority" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacauthority $DAC_PUB
  else
    exit
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} The token contract account (Token Account):${reset} " dactoken
fi
run_cmd "get account $dactoken" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dactoken $DAC_PUB
  else
    exit
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} The money owning account.  It is assumed that all tokens owned will be kept here (Owner Account):${reset} " dacowner
fi
run_cmd "get account $dacowner" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacowner $DAC_PUB
  else
    exit
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} Service provider. If your DAC will not use a service provider, enter none. (Service Account):${reset} " dacservice
fi
if [ "$dacservice" == "none" ]; then
  dacservice=""
else
  run_cmd "get account $dacservice" &>/dev/null
  if [ "$?" != "0" ]; then
    read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
    if [[ $response == "Y" || $response == "y" ]]; then
      create_act $EOS_ACCOUNT $dacservice $DAC_PUB
    else
      exit
    fi
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} Multisig relay (Multisig Account):${reset} " dacmultisigs
fi
run_cmd "get account $dacmultisigs" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacmultisigs $DAC_PUB
  else
    exit
  fi
fi

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} Worker Proposals account (Proposals Account):${reset} " dacproposals
fi
run_cmd "get account $dacproposals" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create this account now?:${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacproposals $DAC_PUB
  else
    exit
  fi
fi

echo "Set token contract on $dactoken ..."
run_cmd "set contract "$dactoken" "$DACCONTRACTS/eosdactoken/output/jungle/eosdactokens" -p $dactoken"

if [ prompt_for_input ]; then
  read -p " > ${prompt_color} What Token Symbol do you want to create for your DAC?${reset} " TOKENSYBMOL
  read -p " > ${prompt_color} How many tokens do you want to create for your DAC?${reset} " DACTOKEN_COUNT_CREATE
  read -p " > ${prompt_color} How many tokens do you want to issue for your DAC?${reset} " DACTOKEN_COUNT_ISSUE
fi

token_stats="$(cleos --wallet-url $WALLET_URL -u $API_URL get currency stats $dactoken $TOKENSYBMOL)"

if [ "$token_stats" == "{}" ]; then
  run_cmd "push action $dactoken create '[\"$dactoken\", \"$DACTOKEN_COUNT_CREATE $TOKENSYBMOL\", 0]' -p $dactoken"
  run_cmd "push action $dactoken issue '[\"$dactoken\", \"$DACTOKEN_COUNT_ISSUE $TOKENSYBMOL\", \"Issue\"]' -p $dactoken"
else
  echo "Token already created and issued."
  echo "$token_stats"
fi

echo "Adjusting compile script for custodian contract..."
sed -i '' "s/kasdactokens/$TOKENSYBMOL/" "$DACCONTRACTS/daccustodian/output/jungle/compile.sh"

echo "Compiling custodian contract..."
cd $DACCONTRACTS/daccustodian
./output/jungle/compile.sh
cd ../..

echo "Set custodian contract on $daccustodian ..."
run_cmd "set contract "$daccustodian" "$DACCONTRACTS/daccustodian/output/jungle/daccustodian" -p $daccustodian"

echo "Set multisig contract on $dacmultisigs ..."
run_cmd "set contract "$dacmultisigs" "$DACCONTRACTS/dacmultisigs/output/jungle/dacmultisigs" -p $dacmultisigs"

## TODO: set config for proposals
#            name service_account = "dacescrow"_n;
#            name authority_account = "dacauthority"_n;
#            name member_terms_account = "eosdactokens"_n;
#            name treasury_account = "eosdacthedac"_n;
#            uint16_t proposal_threshold = 7;
#            uint16_t proposal_approval_threshold_percent = 50;
#            uint16_t claim_threshold = 5;
#            uint16_t claim_approval_threshold_percent = 50;
#            uint32_t escrow_expiry = 30 * 24 * 60 * 60;

#echo "Adjusting compile script for dacproposals contract..."
#sed -i '' "s/dacproposals/$dacproposals/" "$DACCONTRACTS/dacproposals/output/jungle/compile.sh"

#echo "Compiling dacproposals contract..."
#cd $DACCONTRACTS/dacproposals
#chmod +x ./output/jungle/compile.sh
#./output/jungle/compile.sh
#cd ../..
echo "Set proposals contract on $dacproposals ..."
run_cmd "set contract "$dacproposals" "$DACCONTRACTS/dacproposals/output/jungle/dacproposals" -p $dacproposals"

read -p " > ${prompt_color} Next you need a constitution. You can fork the github repo at https://github.com/eosdac/constitution to start, but ultimately you'll need to consult your own lawyers to ensure your DAC is set up according to your own legal needs. Once you have a raw markdown file of your constitution available online as a URL, enter that here. If you just want to start with our default, just hit enter to use https://github.com/eosdac/constitution/blob/41b17819a3e819f39092f72c29ffd466815868ce/constitution.md${reset}: " CONSTITUTION_URL
if [ "$CONSTITUTION_URL" == "" ]; then
  CONSTITUTION_URL="https://github.com/eosdac/constitution/blob/41b17819a3e819f39092f72c29ffd466815868ce/constitution.md"
fi
wget -O constitution.md "$CONSTITUTION_URL"
ARCH=$( uname )
if [ "$ARCH" == "Darwin" ]; then
  CON_MD5=$(md5 constitution.md | cut -d' ' -f4)
else
  CON_MD5=$(md5sum constitution.md | cut -d' ' -f1)
fi
rm -f constitution.md

echo "[\"$CONSTITUTION_URL\", \"$CON_MD5\"]" > terms.json
cat terms.json
run_cmd "push action $dactoken newmemterms terms.json -p $dactoken"
rm -f terms.json

echo "[$daccustodian]" > token_config.json
run_cmd "push action $dactoken updateconfig token_config.json -p $dactoken"
rm -f token_config.json

echo ""
echo "============================================================="
echo "Time to see some configuration variables for your DAC. Just hit enter to go with the defaults"
echo "============================================================="
echo ""

echo "How many $TOKENSYBMOL does a member need to lock up in order to register as a custodian candidate? This ensure candidates have skin in the game to protect the value of the $TOKENSYBMOL token which secures the DAC."
read -p " > ${prompt_color} lockupasset (35000): ${reset}" lockupasset
if [ "$lockupasset" == "" ]; then
  lockupasset="35000"
fi
echo "How many votes does each member get when voting for custodians?"
read -p " > ${prompt_color} maxvotes (5): ${reset}" maxvotes
if [ "$maxvotes" == "" ]; then
  maxvotes="5"
fi
echo "How many custodians will be elected to the custodian board?"
read -p " > ${prompt_color} numelected (12): ${reset}" numelected
if [ "$numelected" == "" ]; then
  numelected="12"
fi
echo "How long will each custodian period be in seconds (default is 7 days, but you can set this to something small like 60 for testing)?"
read -p " > ${prompt_color} periodlength (604800):${reset} " periodlength
if [ "$periodlength" == "" ]; then
  periodlength="604800"
fi
echo "Which EOS account will have full authentication authority for the DAC?"
read -p " > ${prompt_color} authaccount ($dacauthority):${reset} " authaccount
if [ "$authaccount" == "" ]; then
  authaccount="$dacauthority"
fi
echo "Which EOS account holds the operating revenue of the DAC?"
read -p " > ${prompt_color} tokenholder ($dacowner):${reset} " tokenholder
if [ "$tokenholder" == "" ]; then
  tokenholder="$dacowner"
fi
echo "Which EOS account will act as a legal entity service provider for the DAC? If you do not wish to have a service provider, type none"
read -p " > ${prompt_color} serviceprovider ($dacservice): ${reset}" serviceprovider
if [ "$serviceprovider" == "none" ]; then
  serviceprovider=""
  should_pay_via_service_provider=0
elif [ "$serviceprovider" == "" ]; then
  serviceprovider="$dacservice"
  should_pay_via_service_provider=1
else
  should_pay_via_service_provider=1
fi
echo "What percentage of tokens are needed for a quorum to initially launch the DAC?"
read -p " > ${prompt_color} initial_vote_quorum_percent (15): ${reset}" initial_vote_quorum_percent
if [ "$initial_vote_quorum_percent" == "" ]; then
  initial_vote_quorum_percent="15"
fi
echo "Amount of token value in votes required to trigger the allow a new set of custodians to be set after the initial threshold has been achieved."
read -p " > ${prompt_color} vote_quorum_percent (10):${reset} " vote_quorum_percent
if [ "$vote_quorum_percent" == "" ]; then
  vote_quorum_percent="10"
fi
echo "How many custodians are required to approve highest level actions?"
read -p " > ${prompt_color} auth_threshold_high (10)${reset}: " auth_threshold_high
if [ "$auth_threshold_high" == "" ]; then
  auth_threshold_high="10"
fi
echo "How many custodians are required to approve highest mid actions?"
read -p " > ${prompt_color} auth_threshold_mid (9):${reset} " auth_threshold_mid
if [ "$auth_threshold_mid" == "" ]; then
  auth_threshold_mid="9"
fi
echo "How many custodians are required to approve highest low actions?"
read -p " > ${prompt_color} auth_threshold_low (7): ${reset}" auth_threshold_low
if [ "$auth_threshold_low" == "" ]; then
  auth_threshold_low="7"
fi
echo "How much time before locked up stake can be released back to the candidate using the unstake action (defaults to 90 days)?"
read -p " > ${prompt_color} lockup_release_time_delay (7776000): ${reset}" lockup_release_time_delay
if [ "$lockup_release_time_delay" == "" ]; then
  lockup_release_time_delay="7776000"
fi
echo "What is the maximum amount of EOS pay a custodian can requested as a candidate?"
read -p " > ${prompt_color} requested_pay_max (50): ${reset}" requested_pay_max
if [ "$requested_pay_max" == "" ]; then
  requested_pay_max="50"
fi
echo "[[\"$lockupasset.0000 $TOKENSYBMOL\", $maxvotes, $numelected, $periodlength, \"$authaccount\", \"$tokenholder\", \"$serviceprovider\", $should_pay_via_service_provider, $initial_vote_quorum_percent, $vote_quorum_percent, $auth_threshold_high, $auth_threshold_mid, $auth_threshold_low, $lockup_release_time_delay, \"$requested_pay_max.0000 EOS\"]]" > dac_config.json
echo "Setting dac configuration on $daccustodian"
cat dac_config.json
run_cmd "push action $daccustodian updateconfig dac_config.json -p $dacauthority"
rm -f dac_config.json
