const NEST_NodeAssignment = artifacts.require("NEST_NodeAssignment");
const Web3 = require("web3");
const web3 = new Web3();

let contractInstance = new web3.eth.Contract([
  {
    "constant": true,
    "inputs": [
      {
        "name": "name",
        "type": "string"
      }
    ],
    "name": "checkAddress",
    "outputs": [
      {
        "name": "contractAddress",
        "type": "address"
      }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  },
  {
    "constant": true,
    "inputs": [
      {
        "name": "man",
        "type": "address"
      }
    ],
    "name": "checkOwners",
    "outputs": [
      {
        "name": "",
        "type": "bool"
      }
    ],
    "payable": false,
    "stateMutability": "view",
    "type": "function"
  }
], '0x1Ea8B4793C64eC6677fe0aE71BC4915D18F118a4');

module.exports = function (deployer) {
  deployer.deploy(NEST_NodeAssignment, contractInstance.options.address);
};
