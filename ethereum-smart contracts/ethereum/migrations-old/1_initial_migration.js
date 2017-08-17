try {
  var Migrations = artifacts.require("./Migrations.sol");

  module.exports = function(deployer) {
    deployer.deploy(Migrations, {gas: 1550000});
  };
} catch (e) {
  module.exports = function(deployer) {
    deployer.deploy(Migrations, {gas: 1550000});
  };
}