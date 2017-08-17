import { GET_SPREAD, RECEIVE_SPREAD, SEND_BID, SEND_OFFER, RECEIVE_BID, RECEIVE_OFFER } from '../constants';
import { createReducer } from '../utils/misc';

const initialState = {
    loaded: false,
};

export default createReducer(initialState, {
    [GET_SPREAD]: (state) =>
        Object.assign({}, state, {
        }),
    [RECEIVE_SPREAD]: (state, payload) =>
        Object.assign({}, state, {
            spread: payload.spread,
            loaded: true,
        }),
    [SEND_BID]: (state) =>
        Object.assign({}, state, {
        }),
    [RECEIVE_BID]: (state, payload) =>
        Object.assign({}, state, {
            bid_hashes: payload.bid_result
        }),
    [SEND_OFFER]: (state) =>
        Object.assign({}, state, {
        }),
    [RECEIVE_OFFER]: (state, payload) =>
        Object.assign({}, state, {
            offer_hash: payload.offer_result.hash
        }),
});
