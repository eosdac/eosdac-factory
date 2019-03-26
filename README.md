# The eosDAC DAC Factory

Eventually we plan to make building your own DAC (Decentralized Autonomous Community) as easy as following some prompts in an easy-to-use interface. Until we get there, we've put together some shell scripts to automate creating your own DAC on the Jungle Testnet. These scripts should get you familiar with the accounts, contracts, permissions, authorizations, APIs, tools, and interfaces that go into a fully working DAC.

To get started, first run `./build_eos_tools.sh` to update and build the latest version of the EOSIO software and eosio.cdt compiler. Note, this will take quite some time to run depending on the speed of your computer.

Next, open a new terminal window and start your key server with `./keosd.sh`

Finally, run `./dacfactory.sh` and follow the prompts to create your own DAC!

You'll have an action scraper which takes on-chain data and stores it in mongodb for you: https://github.com/eosdac/Actionscraper-rpc

The memberclient-api which takes that data out of mongodb and makes it available to your member client: https://github.com/eosdac/memberclient-api

And the memberclient itself which uses Quasar and is how your DAC members will interact with the blockchain smart contracts that make up the DAC: https://github.com/eosdac/memberclient/

You can view a view walking through this script here: https://www.youtube.com/watch?v=dtFZjJ1409M
