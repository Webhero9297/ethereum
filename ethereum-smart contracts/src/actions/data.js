import { FETCH_PROTECTED_DATA_REQUEST, RECEIVE_PROTECTED_DATA,
    RECEIVE_EVENTS, GET_EVENTS,
    RECEIVE_DASHBOARD, GET_DASHBOARD,
    RECEIVE_SPREAD, GET_SPREAD,
    RECEIVE_BID, SEND_BID,
    RECEIVE_OFFER, SEND_OFFER,
    CONFIRM_SEND_BID, CONFIRM_SEND_OFFER,
    CONFIRM_ACK_BID, CONFIRM_ACK_OFFER } from '../constants/index';
import { parseJSON } from '../utils/misc';
import { data_about_user,
    get_events, get_dashboard, get_spread,
    send_bid, send_offer,
    send_bid_confirm, send_offer_confirm } from '../utils/http_functions';
import { logoutAndRedirect } from './auth';

export function receiveProtectedData(data) {
    return {
        type: RECEIVE_PROTECTED_DATA,
        payload: {
            data,
        },
    };
}

export function fetchProtectedDataRequest() {
    return {
        type: FETCH_PROTECTED_DATA_REQUEST,
    };
}

export function fetchProtectedData(token) {
    return (dispatch) => {
        dispatch(fetchProtectedDataRequest());
        data_about_user(token)
            .then(parseJSON)
            .then(response => {
                dispatch(receiveProtectedData(response.result));
            })
            .catch(error => {
                if (error.status === 401) {
                    dispatch(logoutAndRedirect(error));
                }
            });
    };
}

function wrapWithDispatch(token, dispatch_out, dispatch_in, prop_name, http_call, param1, param2) {
    return (dispatch) => {
        dispatch({ type: dispatch_out })
        return http_call(token, param1, param2)
            .then(parseJSON)
            .then(response => {
                var payload_out = {
                    type: dispatch_in,
                    payload: {}
                };
                payload_out.payload[prop_name] = response;
                dispatch(payload_out);
            })
            .catch(error => {
                if (error.status === 401) {
                    dispatch(logoutAndRedirect(error));
                }
            });
    };
}


export function getEvents(token) {
    return wrapWithDispatch(token, GET_EVENTS, RECEIVE_EVENTS, 'events', get_events);
}

export function getDashboard(token) {
    return wrapWithDispatch(token, GET_DASHBOARD, RECEIVE_DASHBOARD, 'dashboard', get_dashboard);
}

export function getSpread(token, outcome_id) {
    return wrapWithDispatch(token, GET_SPREAD, RECEIVE_SPREAD, 'spread', get_spread, outcome_id);
}

export function sendBid(token, bid_dict) {
    return wrapWithDispatch(token, SEND_BID, RECEIVE_BID, 'bid_result', send_bid, bid_dict);
}

export function sendOffer(token, offer_dict) {
    return wrapWithDispatch(token, SEND_OFFER, RECEIVE_OFFER, 'offer_result', send_offer, offer_dict);
}

export function confirmBids(token, bids, tx_hashes) {
    var bid_combos = [];
    bids.map((bid, index) => {
        bid_combos.push({
            'bid_hash': bid.bid_hash,
            'tx_hash': tx_hashes.deployedBids[index].tx
        });
    });
    return wrapWithDispatch(token, CONFIRM_SEND_BID, CONFIRM_ACK_BID, 'bid_confirm', send_bid_confirm, bid_combos);
}

export function confirmOffer(token, hash, tx_hash) {
    return wrapWithDispatch(token, CONFIRM_SEND_OFFER, CONFIRM_ACK_OFFER, 'offer_confirm', send_offer_confirm, hash, tx_hash);
}