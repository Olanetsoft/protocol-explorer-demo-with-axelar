const hre = require("hardhat");

async function main() {
  const Bounty = await hre.ethers.deployContract("Bounty", [
    "0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B",
    "0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6",
  ]);

  await Bounty.waitForDeployment();

  console.log(`Bounty contract deployed to ${await Bounty.getAddress()}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Get the address of Axelar Gateway and Gas Service contracts on testnet here: https://docs.axelar.dev/resources/testnet
// Fantom testnet: 0x914576AECA173f6873cB131aa47a4a8983E9f5Ce
// Polygon testnet: 0xF9E379349737c756b73Fc048880c381226974B8C
