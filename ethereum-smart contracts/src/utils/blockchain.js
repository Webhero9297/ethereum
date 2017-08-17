
export function getBalance(ether) {
    return new Promise((resolve, reject) => {
        if (!web3) {
            reject("No web3 object.");
        }
        web3.eth.getBalance(web3.eth.accounts[0], 'latest', (err, res) => {
            if (err) {
                reject(err);
            }
            if (ether) {
                var converted = web3.fromWei(res.toNumber(), 'ether');
                resolve(converted);
            } else {
                resolve(res.toNumber());
            }
        });
    });
};