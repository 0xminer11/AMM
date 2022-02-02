const hre = require("hardhat");

async function main() {

    const Pair= await hre.ethers.getContractFactory("pair");
    const pair = await Pair.deploy();
    await pair.deployed();
    console.log("pair deployed to:", pair.address);

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });