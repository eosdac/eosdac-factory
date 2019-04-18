#!/bin/bash

source ./conf.sh
source ./functions.sh

git submodule update --init --recursive

prompt_color=`tput setaf 6`
reset=`tput sgr0`

WORKINGDIR="$(pwd)"

KEOSD_PID="$(pgrep keosd)"

if (( KEOSD_PID > 0 )); then
  echo "keosd running with process ID $KEOSD_PID"
else
  echo "Please run ./keosd.sh in a separate terminal window to start the EOS key server before running this script."
  exit
fi

DACPREFIX=""
prompt_for_input=true

if [ -f ./dac_conf.sh ]; then
  read -p " > ${prompt_color} It looks like you have a dac_conf.sh file. Would you like to use the values in that file (Y/N)?${reset} " response
  if [[ "$response" == "Y" || "$response" == "y" ]]; then
    echo "Using variables imported from dac_conf.sh:"
    source ./dac_conf.sh
    prompt_for_input=false
  fi
fi

# If you ever don't have enough RAM for an account to set a contract, you can get more with this command:
# ./jungle.sh system buyram dacfactory11 dacfac11cust "10.000 EOS"

echo ""
echo "______  ___  _____  ______ ___  _____ _____ _____________   __"
echo "|  _  \/ _ \/  __ \ |  ___/ _ \/  __ \_   _|  _  | ___ \ \ / /"
echo "| | | / /_\ \ /  \/ | |_ / /_\ \ /  \/ | | | | | | |_/ /\ V / "
echo "| | | |  _  | |     |  _||  _  | |     | | | | | |    /  \ /  "
echo "| |/ /| | | | \__/\ | |  | | | | \__/\ | | \ \_/ / |\ \  | |  "
echo "|___/ \_| |_/\____/ \_|  \_| |_/\____/ \_/  \___/\_| \_| \_/  "
echo ""
echo ""
echo "=============================================================="
echo "=                                                            ="
echo "=                Welcome to the DAC Factory!                 ="
echo "=                                                            ="
echo "=                    provided by eosDAC                      ="
echo "=                                                            ="
echo "=============================================================="
echo " "
if $prompt_for_input ; then
  read -p " > ${prompt_color} What is the name of your DAC?${reset} " dacname
fi

#: <<'END_COMMENT'

if [[ "$dacname" == "" ]]; then
  echo "You need a DAC Name"
  exit
fi

echo "Thank you, $dacname"

if $prompt_for_input ; then
  read -p " > ${prompt_color} Have you already created an EOS account for your DAC (Y/N)?${reset} " response
  if [[ "$response" == "Y" || "$response" == "y" ]]; then
    if $prompt_for_input ; then
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
    read -p " > ${prompt_color} Are you ready to view a private key on screen and save it securely (Y/N)?:${reset} " response
    if [[ "$response" == "Y" || "$response" == "y" ]]; then
      echo "Private Key: $DAC_PVT"
      read -p " > ${prompt_color} Press any key to clear the screen and continue${reset}" response
      clear
      echo " > ${prompt_color} Press verify your private key:${reset} "
      read -s response
      if [[ $response != $DAC_PVT ]]; then
        echo "Private Key does not match!"
        exit
      fi
      echo "Use the following key to create an account using the Jungle Testnet https://monitor.jungletestnet.io/#home"
      echo "Public Key: $DAC_PUB"
      read -p " > ${prompt_color} Press verify your public key:${reset} " response
      if [[ $response != $DAC_PUB ]]; then
        echo "Public Key does not match!"
        exit
      fi
      read -p " > ${prompt_color} Please paste the EOS account name you created:${reset} " EOS_ACCOUNT
      echo "Fantastic! Now go back to the Jungle Testnet https://monitor.jungletestnet.io/#home page, click the faucet link, put in the account $EOS_ACCOUNT, check the Google Captcha, and push Send Coins."
      read -p " > ${prompt_color} Press any key after you are done using the Jungle Testnet faucet for $EOS_ACCOUNT.${reset} " response
    else
      exit
    fi
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

if $prompt_for_input ; then
  read -p " > ${prompt_color} Would you like to use an 8-character prefix for your DAC accounts, and we'll create them with suffixes like cust, auth, mult, tokn, ownr, prop? (Y/N):${reset} " response
  if [[ "$response" == "Y" || "$response" == "y" ]]; then
    read -p " > ${prompt_color} Please enter an 8 charcater DAC prefix using only letters and numbers 1-5:${reset} " DACPREFIX
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} The account holding the custodian (voting) contract (Custodian Account):${reset} " daccustodian
  else
    daccustodian="${DACPREFIX}cust"
  fi
fi
run_cmd "get account $daccustodian" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the daccustodian account ($daccustodian) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $daccustodian $DAC_PUB
    echo "Before we continue, let's hit that faucet one more time so we'll have enough EOS for RAM. This time put in the $daccustodian account: https://monitor.jungletestnet.io/#home"
    read -p "After you are done with the faucet, hit any key." response
    run_cmd "transfer $daccustodian $EOS_ACCOUNT \"100 EOS\" \"\" -p $daccustodian"
  else
    exit
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} An empty account used to represent various permission levels. All other DAC accounts will eventually point back to this (Authority Account):${reset} " dacauthority
  else
    dacauthority="${DACPREFIX}auth"
  fi
fi
run_cmd "get account $dacauthority" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the dacauthority account ($dacauthority) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacauthority $DAC_PUB
  else
    exit
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} The token contract account (Token Account):${reset} " dactoken
  else
    dactoken="${DACPREFIX}tokn"
  fi
fi
run_cmd "get account $dactoken" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the dactoken account ($dactoken) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dactoken $DAC_PUB
  else
    exit
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} The money owning account.  It is assumed that all tokens owned will be kept here (Owner Account):${reset} " dacowner
  else
    dacowner="${DACPREFIX}ownr"
  fi
fi
run_cmd "get account $dacowner" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the dacowner account ($dacowner) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacowner $DAC_PUB
  else
    exit
  fi
fi

if $prompt_for_input ; then
  dacservice=""
  read -p " > ${prompt_color} Will your DAC use a service provider for legal contracts (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    if [ "$DACPREFIX" == "" ]; then
      read -p " > ${prompt_color} Service provider. If your DAC will not use a service provider, enter none. (Service Account):${reset} " dacservice
    else
        dacservice="${DACPREFIX}serv"
    fi
  fi
fi
if [[ "$dacservice" == "none" || "$dacservice" == "" ]]; then
  dacservice=""
else
  run_cmd "get account $dacservice" &>/dev/null
  if [ "$?" != "0" ]; then
    read -p " > ${prompt_color} Would you like to create the dacservice account ($dacservice) now (Y/N)?${reset} " response
    if [[ $response == "Y" || $response == "y" ]]; then
      create_act $EOS_ACCOUNT $dacservice $DAC_PUB
    else
      exit
    fi
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} Multisig relay (Multisig Account):${reset} " dacmultisigs
  else
      dacmultisigs="${DACPREFIX}mult"
  fi
fi
run_cmd "get account $dacmultisigs" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the dacmultisigs account ($dacmultisigs) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacmultisigs $DAC_PUB
  else
    exit
  fi
fi

if $prompt_for_input ; then
  if [ "$DACPREFIX" == "" ]; then
    read -p " > ${prompt_color} Worker Proposals account (Proposals Account):${reset} " dacproposals
  else
      dacproposals="${DACPREFIX}prop"
  fi
fi
run_cmd "get account $dacproposals" &>/dev/null
if [ "$?" != "0" ]; then
  read -p " > ${prompt_color} Would you like to create the dacproposals account ($dacproposals) now (Y/N)?${reset} " response
  if [[ $response == "Y" || $response == "y" ]]; then
    create_act $EOS_ACCOUNT $dacproposals $DAC_PUB
  else
    exit
  fi
fi

echo "Set token contract on $dactoken ..."
run_cmd "set contract "$dactoken" "$DACCONTRACTS/eosdactoken/output/jungle/eosdactokens" -p $dactoken"

if $prompt_for_input ; then
  read -p " > ${prompt_color} What Token Symbol do you want to create for your DAC?${reset} " TOKENSYBMOL
fi

token_stats="$(cleos --wallet-url $WALLET_URL -u $API_URL get currency stats $dactoken $TOKENSYBMOL)"

if [ "$token_stats" == "{}" ]; then
  if $prompt_for_input ; then
    read -p " > ${prompt_color} How many tokens do you want to create for your DAC?${reset} " DACTOKEN_COUNT_CREATE
    read -p " > ${prompt_color} How many tokens do you want to issue for your DAC?${reset} " DACTOKEN_COUNT_ISSUE
  fi
  run_cmd "push action $dactoken create '[\"$dactoken\", \"$DACTOKEN_COUNT_CREATE.0000 $TOKENSYBMOL\", 0]' -p $dactoken"
  run_cmd "push action $dactoken issue '[\"$dactoken\", \"$DACTOKEN_COUNT_ISSUE.0000 $TOKENSYBMOL\", \"Issue\"]' -p $dactoken"
else
  echo "Token already created and issued."
  echo "$token_stats"
fi

echo "Adjusting compile script for custodian contract..."
sed -i '' "s/kasdactokens/$dactoken/" "$DACCONTRACTS/daccustodian/output/jungle/compile.sh"

echo "Compiling custodian contract..."
cd $DACCONTRACTS/daccustodian
./output/jungle/compile.sh
cd ../..

echo "Set custodian contract on $daccustodian ..."
run_cmd "set contract "$daccustodian" "$DACCONTRACTS/daccustodian/output/jungle/daccustodian" -p $daccustodian"

echo "Compiling multisig contract..."
cd $DACCONTRACTS/dacmultisigs
./output/jungle/compile.sh
cd ../..

echo "Set multisig contract on $dacmultisigs ..."
run_cmd "set contract "$dacmultisigs" "$DACCONTRACTS/dacmultisigs/output/jungle/dacmultisigs" -p $dacmultisigs"

echo "Set proposals contract on $dacproposals ..."
run_cmd "set contract "$dacproposals" "$DACCONTRACTS/dacproposals/output/jungle/dacproposals" -p $dacproposals"


if $prompt_for_input ; then
  echo ""
  echo "============================================================="
  echo "Time to see some configuration variables for your proposals contract. Just hit enter to go with the defaults"
  echo "============================================================="
  echo ""

  # TODO: change this to "escrow_account" instead of service account?
  #echo "What escrow account would you like to use for your DAC proposals system?"
  #read -p " > ${prompt_color} service_account (): ${reset}" service_account
  #if [ "$service_account" == "" ]; then
  #  service_account=""
  #fi
  echo "Number of required votes to participate in voting for a proposal?"
  read -p " > ${prompt_color} proposal_threshold (3): ${reset}" proposal_threshold
  if [ "$proposal_threshold" == "" ]; then
    proposal_threshold="3"
  fi
  echo "Required percentage of positive votes to approve a proposal?"
  read -p " > ${prompt_color} proposal_approval_threshold_percent (50): ${reset}" proposal_approval_threshold_percent
  if [ "$proposal_approval_threshold_percent" == "" ]; then
    proposal_approval_threshold_percent="50"
  fi
  echo "Number of required votes to participate in voting for completing a proposal?"
  read -p " > ${prompt_color} claim_threshold (2): ${reset}" claim_threshold
  if [ "$claim_threshold" == "" ]; then
    claim_threshold="2"
  fi
  echo "Required percentage of positive votes to approve a proposal claim?"
  read -p " > ${prompt_color} claim_approval_threshold_percent (30): ${reset}" claim_approval_threshold_percent
  if [ "$claim_approval_threshold_percent" == "" ]; then
    claim_approval_threshold_percent="30"
  fi
  echo "The expiry time set on the created escrow transaction (number of seconds)? This has a default value of 30 days"
  read -p " > ${prompt_color} escrow_expiry (86400): ${reset}" escrow_expiry
  if [ "$escrow_expiry" == "" ]; then
    escrow_expiry="86400"
  fi
fi

echo "Setting configuration on $dacproposals"
echo "{\"new_config\": {\"service_account\": \"\",\"authority_account\": \"$dacauthority\",\"member_terms_account\": \"$dactoken\",\"treasury_account\": \"$dacowner\",\"proposal_threshold\": $proposal_threshold,\"proposal_approval_threshold_percent\": $proposal_approval_threshold_percent,\"claim_threshold\": 5,\"claim_approval_threshold_percent\": $claim_approval_threshold_percent,\"escrow_expiry\": $escrow_expiry}}" > proposal_config.json
cat proposal_config.json
config="$(cleos --wallet-url $WALLET_URL -u $API_URL get table $dacproposals $dacproposals configtype | grep rows | awk '{print $2}')"
if [ "$config" == "[]," ]; then
  run_cmd "push action $dacproposals updateconfig proposal_config.json -p $dacproposals"
else
  run_cmd "push action $dacproposals updateconfig proposal_config.json -p $dacauthority"
fi
rm -f proposal_config.json

if $prompt_for_input ; then
  read -p " > ${prompt_color} Next you need a constitution. You can fork the github repo at https://github.com/eosdac/constitution to start, but ultimately you'll need to consult your own lawyers to ensure your DAC is set up according to your own legal needs. Once you have a raw markdown file of your constitution available online as a URL, enter that here. If you just want to start with our default, just hit enter to use https://raw.githubusercontent.com/eosdac/constitution/41b17819a3e819f39092f72c29ffd466815868ce/constitution.md${reset}: " CONSTITUTION_URL
fi
if [ "$CONSTITUTION_URL" == "" ]; then
  CONSTITUTION_URL="https://raw.githubusercontent.com/eosdac/constitution/41b17819a3e819f39092f72c29ffd466815868ce/constitution.md"
fi
wget -O constitution.md "$CONSTITUTION_URL"
ARCH=$( uname )
if [ "$ARCH" == "Darwin" ]; then
  CON_MD5=$(md5 constitution.md | cut -d' ' -f4)
else
  CON_MD5=$(md5sum constitution.md | cut -d' ' -f1)
fi

#echo "Constitution hash: $CON_MD5"
rm -f constitution.md

echo "[\"$CONSTITUTION_URL\", \"$CON_MD5\"]" > terms.json
cat terms.json
run_cmd "push action $dactoken newmemterms terms.json -p $dactoken"
rm -f terms.json

echo "[$daccustodian]" > token_config.json
run_cmd "push action $dactoken updateconfig token_config.json -p $dactoken"
rm -f token_config.json

if $prompt_for_input ; then
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
  read -p " > ${prompt_color} maxvotes (2): ${reset}" maxvotes
  if [ "$maxvotes" == "" ]; then
    maxvotes="2"
  fi
  echo "How many custodians will be elected to the custodian board?"
  read -p " > ${prompt_color} numelected (5): ${reset}" numelected
  if [ "$numelected" == "" ]; then
    numelected="5"
  fi
  echo "How long will each custodian period be in seconds (default is 7 days, but you can set this to something small like 60 for testing)?"
  read -p " > ${prompt_color} periodlength (604800):${reset} " periodlength
  if [ "$periodlength" == "" ]; then
    periodlength="604800"
  fi
  authaccount="$dacauthority"
  tokenholder="$dacowner"
  serviceprovider="$dacservice"
  if [ "$serviceprovider" == "" ]; then
    should_pay_via_service_provider=0
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
  read -p " > ${prompt_color} auth_threshold_high (4)${reset}: " auth_threshold_high
  if [ "$auth_threshold_high" == "" ]; then
    auth_threshold_high="4"
  fi
  echo "How many custodians are required to approve highest mid actions?"
  read -p " > ${prompt_color} auth_threshold_mid (3):${reset} " auth_threshold_mid
  if [ "$auth_threshold_mid" == "" ]; then
    auth_threshold_mid="3"
  fi
  echo "How many custodians are required to approve highest low actions?"
  read -p " > ${prompt_color} auth_threshold_low (2): ${reset}" auth_threshold_low
  if [ "$auth_threshold_low" == "" ]; then
    auth_threshold_low="2"
  fi
  echo "How much time before locked up stake can be released back to the candidate using the unstake action (defaults to 90 days)?"
  read -p " > ${prompt_color} lockup_release_time_delay (7776000): ${reset}" lockup_release_time_delay
  if [ "$lockup_release_time_delay" == "" ]; then
    lockup_release_time_delay="7776000"
  fi
  echo "What is the maximum amount of $TOKENSYBMOL pay a custodian can request as a candidate?"
  read -p " > ${prompt_color} requested_pay_max (50): ${reset}" requested_pay_max
  if [ "$requested_pay_max" == "" ]; then
    requested_pay_max="50"
  fi
fi

echo "[[\"$lockupasset.0000 $TOKENSYBMOL\", $maxvotes, $numelected, $periodlength, \"$authaccount\", \"$tokenholder\", \"$serviceprovider\", $should_pay_via_service_provider, $initial_vote_quorum_percent, $vote_quorum_percent, $auth_threshold_high, $auth_threshold_mid, $auth_threshold_low, $lockup_release_time_delay, \"$requested_pay_max.0000 $TOKENSYBMOL\"]]" > dac_config.json
echo "Setting dac configuration on $daccustodian"
cat dac_config.json
config="$(cleos --wallet-url $WALLET_URL -u $API_URL get table $daccustodian $daccustodian config | grep rows | awk '{print $2}')"
if [ "$config" == "[]," ]; then
  run_cmd "push action $daccustodian updateconfig dac_config.json -p $daccustodian"
else
  run_cmd "push action $daccustodian updateconfig dac_config.json -p $dacauthority"
fi
rm -f dac_config.json

echo "== Set up member client =="
cd memberclient
yarn install

echo "Modify member client config..."

sed -i '' "s/kasdactokens/$dactoken/" "./src/statics/config.jungle.json"
sed -i '' "s/KASDAC/$TOKENSYBMOL/" "./src/statics/config.jungle.json"
sed -i '' "s/\"totalSupply\"\: 1000000000.0000/\"totalSupply\"\: $DACTOKEN_COUNT_CREATE/" "./src/statics/config.jungle.json"
sed -i '' "s/dacelections/$daccustodian/" "./src/statics/config.jungle.json"
# TODO: add bot
sed -i '' "s/piecesnbitss/piecesnbitss/" "./src/statics/config.jungle.json"
sed -i '' "s/dacmultisigs/$dacmultisigs/" "./src/statics/config.jungle.json"
sed -i '' "s/dacproposals/$dacproposals/" "./src/statics/config.jungle.json"
# TODO: add escrow
sed -i '' "s/eosdacescrow/eosdacescrow/" "./src/statics/config.jungle.json"
sed -i '' "s/dacauthority/$dacauthority/" "./src/statics/config.jungle.json"
sed -i '' "s/eosdacdoshhq/$dacowner/" "./src/statics/config.jungle.json"
sed -i '' "s/http:\/\/ns3119712.ip-51-38-42.eu:3000/http:\/\/localhost:3000/" "./src/statics/config.jungle.json"

echo "Updating language files to replace eosDAC with $dacname"
cd src
grep -lr --exclude-dir=".git" -e "eosDAC" . | xargs sed -i '' -e "s/eosDAC/$dacname/g"
cd ..

if [[ $prompt_for_input == true || "$logo_file_name" == "" ]]; then
  echo "Please save an svg, png, or jpg logo in $WORKINGDIR/memberclient/src/assets/images/ and then include the file name here:"
  read -p " > ${prompt_color} logo file name: ${reset}" logo_file_name
fi
echo "Adding logo to MyLayout.vue..."
sed -i '' "s/logo-main-light.svg/$logo_file_name/" "./src/layouts/MyLayout.vue"
sed -i '' "s/logo-notext-light.svg/$logo_file_name/" "./src/layouts/MyLayout.vue"
sed -i '' "s/logo-main-dark.svg/$logo_file_name/" "./src/layouts/MyLayout.vue"
sed -i '' "s/logo-notext-dark.svg/$logo_file_name/" "./src/layouts/MyLayout.vue"

echo "Building memberclient with quasar build..."
quasar build
cd ..

echo "Configuring watchers..."
cp ./Actionscraper-rpc/watchers/config.jungle.js ./Actionscraper-rpc/watchers/config.js 
sed -i '' "s/eosdac/$dacowner/" "./Actionscraper-rpc/watchers/config.js"
sed -i '' "s/dacelections/$daccustodian/" "./Actionscraper-rpc/watchers/config.js"
sed -i '' "s/kasdactokens/$dactoken/" "./Actionscraper-rpc/watchers/config.js"
sed -i '' "s/dacmultisigs/$dacmultisigs/" "./Actionscraper-rpc/watchers/config.js"
cd ./Actionscraper-rpc/
yarn install
cd ..

echo "Configuring memberclient-api..."
cp ./memberclient-api/config.example.json ./memberclient-api/config.json
sed -i '' "s/\"eosdac\"/\"$dacowner\"/" "./memberclient-api/config.json"
cd ./memberclient-api
yarn install
cd ..

echo "Configuring permissions..."
echo "{
    \"threshold\" : 1,
    \"keys\" : [],
    \"accounts\": [{\"permission\":{\"actor\":\"$dacauthority\", \"permission\":\"active\"}, \"weight\":1}],
    \"waits\": []
}" > resign.json

echo "{
    \"threshold\": 2,
    \"keys\": [],
    \"accounts\": [
        {\"permission\":{\"actor\":\"$dacauthority\", \"permission\":\"med\"}, \"weight\":2},
        {\"permission\":{\"actor\":\"$daccustodian\", \"permission\":\"eosio.code\"}, \"weight\":1}
    ],
    \"waits\": [{\"wait_sec\":3600, \"weight\":1}]
}" > daccustodian_transfer.json

## NOTE: When you are confident, change the keys part to just []

echo "{
    \"threshold\": 1,
    \"keys\": [{\"key\":\"$DAC_PUB\", \"weight\":1}],
    \"accounts\": [
        {\"permission\":{\"actor\":\"$dacauthority\", \"permission\":\"high\"}, \"weight\":1}
    ],
    \"waits\": []
}" > dacauthority_active.json

## NOTE: When you are confident, change the keys part to just []

echo "{
    \"threshold\": 1,
    \"keys\": [{\"key\":\"$DAC_PUB\", \"weight\":1}],
    \"accounts\": [
        {\"permission\":{\"actor\":\"$daccustodian\", \"permission\":\"eosio.code\"}, \"weight\":1}
    ],
    \"waits\": []
}" > dacauthority_owner.json

# These have to be set now because they are required in daccustodian_transfer.json
# These permissions are set in new period to the custodians with each configured threshold
run_cmd "set account permission $dacauthority high $DAC_PUB active -p $dacauthority@owner"
run_cmd "set account permission $dacauthority med $DAC_PUB high -p $dacauthority@owner"
run_cmd "set account permission $dacauthority low $DAC_PUB med -p $dacauthority@owner"
run_cmd "set account permission $dacauthority one $DAC_PUB low -p $dacauthority@owner"

# resign dactokens account to dacauthority@active
run_cmd "set account permission $dactoken active ./resign.json owner -p $dactoken@owner"
run_cmd "set account permission $dactoken owner ./resign.json '' -p $dactoken@owner"

# resign dacmultisigs account to dacauthority@active
run_cmd "set account permission $dacmultisigs active ./resign.json owner -p $dacmultisigs@owner"
run_cmd "set account permission $dacmultisigs owner ./resign.json '' -p $dacmultisigs@owner"

# resign dacowner account to dacauthority@active, must allow timelocked transfers
# from daccustodian@eosio.code
# daccustodian_transfer.json allows the contract to make transfers with a time delay, or
# dacauthority@med without a time delay.  dacowner must have permission in xfer to transfer tokens
run_cmd "set account permission $dacowner xfer ./daccustodian_transfer.json active -p $dacowner@owner"
run_cmd "set action permission $dacowner eosio.token transfer xfer -p $dacowner@owner"
# Resign eosdacthedac
run_cmd "set account permission $dacowner active ./resign.json owner -p $dacowner@owner"
run_cmd "set account permission $dacowner owner ./resign.json '' -p $dacowner@owner"

# Create xfer permission and give it permission to transfer TESTDAC tokens
run_cmd "set account permission $daccustodian xfer ./daccustodian_transfer.json active -p $daccustodian@owner"
run_cmd "set action permission $daccustodian $dactoken transfer xfer -p $daccustodian@owner"
# Resign daccustodian
run_cmd "set account permission $daccustodian active ./resign.json owner -p $daccustodian@owner"
run_cmd "set account permission $daccustodian owner ./resign.json '' -p $daccustodian@owner"

# Allow high to call any action on daccustodian
run_cmd "set action permission $dacauthority $daccustodian '' high -p $dacauthority@owner"
# These 2 actions require a medium permission
run_cmd "set action permission $dacauthority $daccustodian firecust med -p $dacauthority@owner"
run_cmd "set action permission $dacauthority $daccustodian firecand med -p $dacauthority@owner"
# Allow one to call the multisig actions
run_cmd "set action permission $dacauthority $dacmultisigs '' one -p $dacauthority@owner"

# set dacauthority@active to point to daccustodian@eosio.code
run_cmd "set account permission $dacauthority active ./dacauthority_active.json owner -p $dacauthority@owner"
run_cmd "set account permission $dacauthority owner ./dacauthority_owner.json "" -p $dacauthority@owner"

rm ./resign.json
rm ./daccustodian_transfer.json
rm ./dacauthority_active.json
rm ./dacauthority_owner.json


if [[ ($prompt_for_input == true || "$create_test_custodians" == "") && DACPREFIX != "" ]]; then
  read -p " > ${prompt_color} Would you like to create test custodians, vote them in, and call new period to activate the DAC? (Y/N) ${reset}" create_test_custodians
  if [[ $create_test_custodians == "Y" || $create_test_custodians == "y" ]]; then
    create_test_custodians="Y"
  else
    create_test_custodians="N"
  fi
fi

if [[ "$create_test_custodians" == "Y" && DACPREFIX != "" ]]; then
  if [[ "$CUSTODIAN_PVT" == "" && "$CUSTODIAN_PUB" == "" ]]; then
    echo "Generating keys for custodians..."
    CUSTODIAN_KEYS="$(cleos create key --to-console | awk '{ print $3 }')"
    CUSTODIAN_PVT="$(echo $CUSTODIAN_KEYS | head -n1 | awk '{print $1;}')"
    CUSTODIAN_PUB="$(echo $CUSTODIAN_KEYS | head -n1 | awk '{print $2;}')"
    read -p " > ${prompt_color} Are you ready to view a private key on screen and save it securely (Y/N)?:${reset} " response
    if [[ "$response" == "Y" || "$response" == "y" ]]; then
      echo "Private Key: $CUSTODIAN_PVT"
      read -p " > ${prompt_color} Press any key to clear the screen and continue${reset}" response
      clear
      echo " > ${prompt_color} Press verify your private key:${reset} "
      read -s response
      if [[ $response != $CUSTODIAN_PVT ]]; then
        echo "Private Key does not match!"
        exit
      fi
      echo "Public Key: $CUSTODIAN_PUB"
      read -p " > ${prompt_color} Press verify your public key:${reset} " response
      if [[ $response != $CUSTODIAN_PUB ]]; then
        echo "Public Key does not match!"
        exit
      fi
    else
      exit
    fi
  fi

  run_cmd "wallet unlock --name $EOS_ACCOUNT < $EOS_ACCOUNT.wallet_password"
  run_cmd "wallet import --name $EOS_ACCOUNT --private-key $CUSTODIAN_PVT"

  echo "Before we continue, let's hit the faucet so we'll have enough EOS for RAM. This time put in the $dactoken account: https://monitor.jungletestnet.io/#home"
  read -p "After you are done with the faucet, hit any key." response
  run_cmd "transfer $dactoken $EOS_ACCOUNT \"100 EOS\" \"\" -p $dactoken"
  echo "And one more time with the faucet for the $dacowner account: https://monitor.jungletestnet.io/#home"
  read -p "After you are done with the faucet, hit any key." response
  run_cmd "transfer $dacowner $EOS_ACCOUNT \"100 EOS\" \"\" -p $dacowner"

  read -p " > ${prompt_color} How many tokens would you like to transfer to each of your test custodians? Keep in mind you have $DACTOKEN_COUNT_ISSUE tokens and need $initial_vote_quorum_percent percent used to launch the DAC. ${reset}" test_custodian_transfer_amount

  # TODO: loop through and create as many custodians as needed based on the config
  # TODO: for now, just create 5
  custodian1="${DACPREFIX}cu11"
  run_cmd "get account $custodian1" &>/dev/null
  if [ "$?" != "0" ]; then
    create_act $EOS_ACCOUNT $custodian1 $CUSTODIAN_PUB
    ## TODO: adjust the amount transferred based on settings to reach active DAC
    run_cmd "transfer -c $dactoken $dactoken $custodian1 \"$test_custodian_transfer_amount.0000 $TOKENSYBMOL\" \"$custodian1\" -p $dactoken"
    run_cmd "push action $dactoken memberreg '[\"$custodian1\", \"$CON_MD5\"]' -p $custodian1"
    run_cmd "transfer -c $dactoken $custodian1 $daccustodian \"$lockupasset.0000 $TOKENSYBMOL\" \"$daccustodian\" -p $custodian1"
    run_cmd "push action $daccustodian nominatecand '[\"$custodian1\", \"1.0000 $TOKENSYBMOL\"]' -p $custodian1"
    run_cmd "push action $daccustodian votecust '[\"$custodian1\",[\"$custodian1\"]]' -p $custodian1"
  fi
  custodian2="${DACPREFIX}cu12"
  run_cmd "get account $custodian2" &>/dev/null
  if [ "$?" != "0" ]; then
    create_act $EOS_ACCOUNT $custodian2 $CUSTODIAN_PUB
    run_cmd "transfer -c $dactoken $dactoken $custodian2 \"$test_custodian_transfer_amount.0000 $TOKENSYBMOL\" \"$custodian2\" -p $dactoken"
    run_cmd "push action $dactoken memberreg '[\"$custodian2\", \"$CON_MD5\"]' -p $custodian2"
    run_cmd "transfer -c $dactoken $custodian2 $daccustodian \"$lockupasset.0000 $TOKENSYBMOL\" \"$daccustodian\" -p $custodian2"
    run_cmd "push action $daccustodian nominatecand '[\"$custodian2\", \"1.0000 $TOKENSYBMOL\"]' -p $custodian2"
    run_cmd "push action $daccustodian votecust '[\"$custodian2\",[\"$custodian2\"]]' -p $custodian2"
  fi
  custodian3="${DACPREFIX}cu13"
  run_cmd "get account $custodian3" &>/dev/null
  if [ "$?" != "0" ]; then
    create_act $EOS_ACCOUNT $custodian3 $CUSTODIAN_PUB
    run_cmd "transfer -c $dactoken $dactoken $custodian3 \"$test_custodian_transfer_amount.0000 $TOKENSYBMOL\" \"$custodian3\" -p $dactoken"
    run_cmd "push action $dactoken memberreg '[\"$custodian3\", \"$CON_MD5\"]' -p $custodian3"
    run_cmd "transfer -c $dactoken $custodian3 $daccustodian \"$lockupasset.0000 $TOKENSYBMOL\" \"$daccustodian\" -p $custodian3"
    run_cmd "push action $daccustodian nominatecand '[\"$custodian3\", \"1.0000 $TOKENSYBMOL\"]' -p $custodian3"
    run_cmd "push action $daccustodian votecust '[\"$custodian3\",[\"$custodian3\"]]' -p $custodian3"
  fi
  custodian4="${DACPREFIX}cu14"
  run_cmd "get account $custodian4" &>/dev/null
  if [ "$?" != "0" ]; then
    create_act $EOS_ACCOUNT $custodian4 $CUSTODIAN_PUB
    run_cmd "transfer -c $dactoken $dactoken $custodian4 \"$test_custodian_transfer_amount.0000 $TOKENSYBMOL\" \"$custodian4\" -p $dactoken"
    run_cmd "push action $dactoken memberreg '[\"$custodian4\", \"$CON_MD5\"]' -p $custodian4"
    run_cmd "transfer -c $dactoken $custodian4 $daccustodian \"$lockupasset.0000 $TOKENSYBMOL\" \"$daccustodian\" -p $custodian4"
    run_cmd "push action $daccustodian nominatecand '[\"$custodian4\", \"1.0000 $TOKENSYBMOL\"]' -p $custodian4"
    run_cmd "push action $daccustodian votecust '[\"$custodian4\",[\"$custodian4\"]]' -p $custodian4"
  fi
  custodian5="${DACPREFIX}cu15"
  run_cmd "get account $custodian5" &>/dev/null
  if [ "$?" != "0" ]; then
    create_act $EOS_ACCOUNT $custodian5 $CUSTODIAN_PUB
    ## TODO: adjust the amount transferred based on settings to reach active DAC
    run_cmd "transfer -c $dactoken $dactoken $custodian5 \"$test_custodian_transfer_amount.0000 $TOKENSYBMOL\" \"$custodian5\" -p $dactoken"
    run_cmd "push action $dactoken memberreg '[\"$custodian5\", \"$CON_MD5\"]' -p $custodian5"
    run_cmd "transfer -c $dactoken $custodian5 $daccustodian \"$lockupasset.0000 $TOKENSYBMOL\" \"$daccustodian\" -p $custodian5"
    run_cmd "push action $daccustodian nominatecand '[\"$custodian5\", \"1.0000 $TOKENSYBMOL\"]' -p $custodian5"
    run_cmd "push action $daccustodian votecust '[\"$custodian5\",[\"$custodian5\"]]' -p $custodian5"
  fi
fi

run_cmd "push action $daccustodian newperiod '{\"message\":\"New Period\"}' -p $custodian5"

echo ""
echo "====== CONGRATULATIONS! ======"
echo ""

read -p " > ${prompt_color} Would you like to save all your DAC variables to dac_conf.sh so you can easily run this again? Note, this will include your private key. (Y/N)?${reset} " response
if [[ "$response" == "Y" || "$response" == "y" ]]; then
  echo "" > dac_conf.sh
  echo "dacname=\"$dacname\"" >> dac_conf.sh
  echo "DAC_PVT=\"$DAC_PVT\"" >> dac_conf.sh
  echo "DAC_PUB=\"$DAC_PUB\"" >> dac_conf.sh
  echo "EOS_ACCOUNT=\"$EOS_ACCOUNT\"" >> dac_conf.sh
  echo "DACPREFIX=\"$DACPREFIX\"" >> dac_conf.sh
  echo "daccustodian=\"$daccustodian\"" >> dac_conf.sh
  echo "dacauthority=\"$dacauthority\"" >> dac_conf.sh
  echo "dactoken=\"$dactoken\"" >> dac_conf.sh
  echo "dacowner=\"$dacowner\"" >> dac_conf.sh
  echo "dacservice=\"$dacservice\"" >> dac_conf.sh
  echo "dacmultisigs=\"$dacmultisigs\"" >> dac_conf.sh
  echo "dacproposals=\"$dacproposals\"" >> dac_conf.sh
  echo "TOKENSYBMOL=\"$TOKENSYBMOL\"" >> dac_conf.sh
  echo "DACTOKEN_COUNT_CREATE=\"$DACTOKEN_COUNT_CREATE\"" >> dac_conf.sh
  echo "DACTOKEN_COUNT_ISSUE=\"$DACTOKEN_COUNT_ISSUE\"" >> dac_conf.sh
  echo "CONSTITUTION_URL=\"$CONSTITUTION_URL\"" >> dac_conf.sh
  echo "CON_MD5=\"$CON_MD5\"" >> dac_conf.sh
  echo "lockupasset=\"$lockupasset\"" >> dac_conf.sh
  echo "maxvotes=\"$maxvotes\"" >> dac_conf.sh
  echo "numelected=\"$numelected\"" >> dac_conf.sh
  echo "periodlength=\"$periodlength\"" >> dac_conf.sh
  echo "authaccount=\"$authaccount\"" >> dac_conf.sh
  echo "tokenholder=\"$tokenholder\"" >> dac_conf.sh
  echo "serviceprovider=\"$serviceprovider\"" >> dac_conf.sh
  echo "should_pay_via_service_provider=\"$should_pay_via_service_provider\"" >> dac_conf.sh
  echo "initial_vote_quorum_percent=\"$initial_vote_quorum_percent\"" >> dac_conf.sh
  echo "vote_quorum_percent=\"$vote_quorum_percent\"" >> dac_conf.sh
  echo "auth_threshold_high=\"$auth_threshold_high\"" >> dac_conf.sh
  echo "auth_threshold_mid=\"$auth_threshold_mid\"" >> dac_conf.sh
  echo "auth_threshold_low=\"$auth_threshold_low\"" >> dac_conf.sh
  echo "lockup_release_time_delay=\"$lockup_release_time_delay\"" >> dac_conf.sh
  echo "requested_pay_max=\"$requested_pay_max\"" >> dac_conf.sh
  echo "proposal_threshold=\"$proposal_threshold\"" >> dac_conf.sh
  echo "proposal_approval_threshold_percent=\"$proposal_approval_threshold_percent\"" >> dac_conf.sh
  echo "claim_threshold=\"$claim_threshold\"" >> dac_conf.sh
  echo "claim_approval_threshold_percent=\"$claim_approval_threshold_percent\"" >> dac_conf.sh
  echo "escrow_expiry=\"$escrow_expiry\"" >> dac_conf.sh
  echo "logo_file_name=\"$logo_file_name\"" >> dac_conf.sh
  echo "create_test_custodians=\"$create_test_custodians\"" >> dac_conf.sh
  echo "CUSTODIAN_PVT=\"$CUSTODIAN_PVT\"" >> dac_conf.sh
  echo "CUSTODIAN_PUB=\"$CUSTODIAN_PUB\"" >> dac_conf.sh
  echo "test_custodian_transfer_amount=\"$test_custodian_transfer_amount\"" >> dac_conf.sh
  echo "dac_conf.sh saved. Please be careful with this file as it contains your private key."
fi

