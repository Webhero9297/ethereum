import {
    DEPLOY_BID,
    DEPLOY_OFFER,
    COMPLETE_BID,
    COMPLETE_OFFER
 } from '../constants/index';
import { parseJSON } from '../utils/misc';
import { logoutAndRedirect } from './auth';
import { getBalance } from '../utils/blockchain';
import { default as contract } from 'truffle-contract';
import offer_artifacts from '../../ethereum/contracts/Offer.sol';

const Promise = require("bluebird"); // for map function

var OfferContract = contract(offer_artifacts);

if (window.web3) {
    OfferContract.setProvider(window.web3.currentProvider);
}

function wrapTruffleWithDispatch(dispatch_out, dispatch_in, prop_name, truffle_call, ...args) {
    return (dispatch) => {
        dispatch({ type: dispatch_out })
        return truffle_call.apply(null, args)
            .then(response => {
                var payload_out = {
                    type: dispatch_in,
                    payload: {}
                };
                payload_out.payload[prop_name] = response;
                dispatch(payload_out);
            });
    };
}

function makeOfferTruffle(odds, coverage, hash) {
    var wallet = web3.eth.accounts[0];
    return getBalance(true).then((ether) => {
        if (coverage <= ether) {
            if (window.web3) {
                OfferContract.setProvider(window.web3.currentProvider);
            }
            return OfferContract.new(odds, window.web3.toWei(coverage, 'ether'), wallet, hash,
                web3.eth.accounts[9], 20,
                {from: wallet, value: window.web3.toWei(coverage, 'ether')}).then((pre_instance) => {
                return pre_instance.address;
            });
        } else {
            throw("Noe enough ether.");
        }
    });
}

function makeBidsTruffle(bids, totalValue) {
    var wallet = web3.eth.accounts[0];
    return getBalance(true).then((ether) => {
        if (totalValue <= ether) {
            if (window.web3) {
                OfferContract.setProvider(window.web3.currentProvider);
            }
            return Promise.map(bids, (bid) => {
                var contract = OfferContract.at(bid.offer_tx);
                return contract.bid({from: wallet, value: window.web3.toWei(bid.value, 'ether')})
            });
        } else {
            throw("Noe enough ether.");
        }
    });
}

export function makeBids(bids, totalValue) {
    return wrapTruffleWithDispatch(DEPLOY_BID, COMPLETE_BID,
        'deployedBids', makeBidsTruffle, bids, totalValue);
}

export function makeOffer(odds, coverage, hash) {
    return wrapTruffleWithDispatch(DEPLOY_OFFER, COMPLETE_OFFER,
        'deployedOffer', makeOfferTruffle, odds, coverage, hash);
}