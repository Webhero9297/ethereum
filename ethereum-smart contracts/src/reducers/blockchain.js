import { 
    DEPLOY_BID,
    DEPLOY_OFFER,
    COMPLETE_BID,
    COMPLETE_OFFER
 } from '../constants';
import { createReducer } from '../utils/misc';

const initialState = {

}

export default createReducer(initialState, {
    [COMPLETE_OFFER]: (state, payload) =>
        Object.assign({}, state, {
            contractHash: payload,
            deploying: false,
        }),
    [DEPLOY_OFFER]: (state) =>
        Object.assign({}, state, {
            deploying: true,
        }),
    [COMPLETE_BID]: (state, payload) =>
        Object.assign({}, state, {
            transactionHash: payload,
            deploying: false,
        }),
    [DEPLOY_BID]: (state) =>
        Object.assign({}, state, {
            deploying: true,
        }),
});
