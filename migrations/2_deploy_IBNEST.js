const IterableMapping = artifacts.require("IterableMapping");
const IBNEST = artifacts.require("./IBNEST.sol");

async function doDeploy(deployer, network) {
  await deployer.deploy(IterableMapping);
  await deployer.link(IterableMapping, [IBNEST]);
  await deployer.deploy(IBNEST);
}

module.exports = (deployer, network) => {
  deployer.then(async() => {
    await doDeploy(deployer, network);
  });
};