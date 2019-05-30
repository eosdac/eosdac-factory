# The eosDAC DAC Factory

Eventually we plan to make building your own DAC (Decentralized Autonomous Community) as easy as following some prompts in an easy-to-use interface. Until we get there, we've put together some shell scripts to automate creating DACs on the Jungle Testnet for our own testing purposes. Please understand, these scripts are not ready for production use and our systems are changing constantly, including significant contract changes which, in the future, may mean you do not need to deploy your own DAC contracts, but can use ours with your own DAC scope. That said, if you'd like to better understand how things work as they are now, these scripts should get you familiar with the accounts, contracts, permissions, authorizations, APIs, tools, and interfaces that go into a fully working DAC.

Currently, these tools do require technical understanding. If you get stuck, we'll be happy to help in the eosDAC Discord #support channel with in reason: https://discord.io/eosdac The more time we spend in support is less time available for getting our tools production ready.

Requirements include:

* <a href="https://nodejs.org/en/download/">NodeJS</a>
* <a href="https://docs.mongodb.com/manual/installation/">MongoDB</a>
* <a href="https://www.rabbitmq.com/download.html">RabbitMQ</a>
* <a href="http://pm2.keymetrics.io/docs/usage/quick-start/#installation">pm2</a>
* <a href="https://quasar-framework.org/guide/index.html">Quasar</a>

Before you get started, you may want to fork the client extension repo and customize it for your DAC: https://github.com/eosdac/eosdac-client-extension During the setup process, you'll be prompted for the git url (ending in .git) of your client extension. If you don't have one, you can just use this default for now.

You may also want to fork the constitution repo and create your own constitution document: https://github.com/eosdac/eosdac-constitution If you don't have one, you can use ours as a default for now.

To get started, first run `./build_eos_tools.sh` to update and build the latest version of the EOSIO software and eosio.cdt compiler. Note, this will take quite some time to run depending on the speed of your computer. If you already have eosio installed (so you can run cleos commands) and eosio.cdt installed (so you can install smart contracts), you can skip this step.

Next, open a new terminal window and start your key server with `./keosd.sh`

Go ahead and start MongoDB as well using `mongod` if it's not already running. The default settings should be fine for now.

You'll also want to start RabbitMQ using `rabbitmq-server` if it's not already running.

Finally, run `./eosdacfactory.sh` and follow the prompts to create your own DAC!

You can view a view walking through this script here: https://www.youtube.com/watch?v=dtFZjJ1409M

The DAC Factory pulls in code via submodules from the following repositories:

https://github.com/eosdac/eosdac-client
https://github.com/eosdac/eosdac-api
https://github.com/eosdac/eosio-statereceiver

You may not need it, but if you want to run multiple DACs, you'll want to separate them out into separate RabbitMQ vhosts which you can create via the interface at port 15672 such as http://localhost:15672/#/vhosts (<a href="https://www.tutlane.com/tutorial/rabbitmq/rabbitmq-virtual-hosts">more on that here</a>). As is, it just uses the guest:guest account on localhost with an empty vhost.

Here's the basic flow of what the dacfactory.sh script does:

* Create an account which will then create all the other accounts needed for the different smart contracts of the DAC.
* At various points, use the Jungle faucet to get more testnet EOS for your accounts.
* Create accounts. Modify, compile, and deploy contracts to those accounts.
* Adjust permissions on all accounts so the authory account is in place to control the DAC.
* Create test custodian accounts and transfer tokens to them so they can register as members of the DAC, create a profile, become custodian candidates, and elect themselves as custodians for further testing.
* Customize configurations for the eosdac-api which includes multiple parts. Some parts pull blocks off a state history node and throw them into RabbitMQ for later processing. Other parts process the raw data and store it in MongoDB. Other parts take that raw data and store it as structured data such as worker proposals and multisignature transactions. Finally, an API makes that MongoDB data available to the front end client inteface.
* The eosDAC Client is modified to use all the accounts you created and point to the proper API endpoints.

After you've run the script, you can save all the variables you used to run it again at a later time and update things further. Keep in mind, this file will store your private keys in plain text.

Finally, go to the eosdac-api folder and run `pm2 start` to start the API, filler, and procoessor needed to collect on chain data and make it available to the front end client.

This script assumes you want a DAC with 5 custodians (as it currently only creates 5 custodians), but you can certainly create more if you want, though you would have to customize the script for your needs.

Going through the script is a good way to learn about the various configuration files involved and the accounts as well.

Here are the main configuration files you should double check:

* eosdac-api/ecosystem.config.js

    The HOST_NAME is set to localhost with this script, but if your eosdac-api will be hosted on a public server, you'll want to replace this with wherever you are hosting your eosdac client. If your API will be on a separate domain, then ensure you have the proper CORS headers set. An example nginx proxy config for the API looks like this, assuming you're running the API on port 8383:
    ```
    location ~ ^/v1/eosdac {
        add_header Access-Control-Origin *;
        proxy_pass  http://127.0.0.1:8383;
    }
    ```
    If you're running multiple DACs on the same machine, you'll want to give each service a separate name in this file and a separate SERVER_PORT.

* eosdac-api/jungle.config.js

    This file is where you set your MongoDB settings, RabbitMQ settings, and EOS contract information you want to make available to the API. If you're running either of these services somewhere other than localhost, you'll want to adjust this accordingly. Also, if you are using a specific RabbitMQ account login and password or a specified vhost, you'll want to update that here.

* eosdac-client/src/extensions/statics/config/build.config.json

    Here you'll want to modify host_no_backslash and meta_description. Again, if you're serving this somewhere other than localhost, you'll want to make that adjustment here.

* eosdac-client/src/extensions/statics/config/config.jungle.json

    This is where all your accounts are configured for the member client, along with endpoints (such as the eosdac-api url configured with memberclient_state_api) the client needs.

As of this writing, the worker proposal system is not complete and is still being developed.

Good luck and please feel free to ask us questions. If you do end up creating a real DAC on Mainnet along with your own community token, please consider reserving some of those tokens for an airdrop on the active, voting members of the eosDAC community as a contribution for the value this open source software has brought to you. Please do contact us and let us know you've created a DAC using this software.

Thank you!


