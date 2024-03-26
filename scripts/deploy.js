const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [signer] = await ethers.getSigners();

  const Erc = await ethers.getContractFactory("MShop", signer);
  const erc = await Erc.deploy();
  await erc.getDeployedCode();
  console.log(await erc.getAddress());
  console.log(await erc.token());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
