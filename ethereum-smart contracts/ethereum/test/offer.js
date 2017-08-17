var Offer = artifacts.require("./Offer.sol");

contract('Offer', (accounts) => {

  var house = accounts[0];
  var bidder = accounts[1];
  var seller = accounts[2];
  var odds = 2;
  var houseRatio = 20;
  var coverage = web3.toWei(2, 'ether');
  var testHash = "testHash";
  var testBid = 1;

  var deploy = () => {
    return Offer.new(odds, coverage, seller, testHash, house, houseRatio,
      {from: seller, value: coverage}).then((pre_instance) => {
      return Offer.at(pre_instance.address).then((instance) => {
        return instance;
      });
    });
  };

  it("Should initialize without error", () => {
    return deploy();
  });

  it('Should contain the proper instance variables', () => {
    return deploy().then((instance) => {
      var promises = [
        instance.Odds.call().then((result) => {
          assert.equal(result.toNumber(), 2, "Odds did not persist");
        }),
        instance.Coverage.call().then((result) => {
          assert.equal(result.toNumber(), coverage, "Coverage did not persist");
        }),
        instance.RemainingCoverage.call().then((result) => {
          assert.equal(result.toNumber(), coverage, "Coverage did not persist");
        })
      ];
      return Promise.all(promises);
    });
  })

  it('Should allow bids up to the coverage amount', () => {
    return deploy().then((instance) => {
      instance.bid({from: bidder, value: web3.toWei(testBid, 'ether') }).then((tx_info) => {
        assert.equal(tx_info.logs.length, 1, "One event was not triggered");
        assert.equal(tx_info.logs[0].event, "newBid", "newBid was not triggered");
        assert.equal(tx_info.logs[0]
        .args.amount.toNumber(), web3.toWei(testBid, 'ether'),
          "Bid value is incorrect");
      });
    });
  });

  it("Should respond to Oraclize.it event triggers and send resultant appropriately", () => {
    return deploy().then((instance) => {
      instance.bid({from: bidder, value: web3.toWei(1, 'ether')});
      instance.update({value: web3.toWei(0.1, 'ether') });
      var watcher = instance.bidWin({fromBlock: 0, toBlock: 'latest'});
      return new Promise((resolve, reject) => {
        setTimeout(() => reject("No result event fired."), 15000);
        watcher.watch((err, tx_info) => {
          assert.equal(tx_info.event, "bidWin", "bidWin was not triggered");
          var housePaybackResult = tx_info.args.houseAmount;
          assert.equal(web3.fromWei(housePaybackResult, 'ether').toNumber(), testBid * odds * (houseRatio / 100),
            "House did not receive the correct amount");
          watcher.stopWatching();
          resolve();
        });
      }).then(() => {});
    });
  });
});