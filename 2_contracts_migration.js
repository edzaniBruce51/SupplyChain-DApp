const erc20Token = artifacts.require("./erc20Tokens.sol");
const SupplyChain = artifacts.require("./SupplyChain.sol");

module.exports = function(deployer) {
  deployer.deploy(erc20Token, 10000, "TotalSem Token", 18, "TotalSem");    // These parameters are passed to the constructor
  deployer.deploy(SupplyChain);
};
