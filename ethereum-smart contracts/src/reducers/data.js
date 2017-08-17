import { RECEIVE_PROTECTED_DATA, FETCH_PROTECTED_DATA_REQUEST,
    GET_EVENTS, RECEIVE_EVENTS,
    GET_DASHBOARD, RECEIVE_DASHBOARD } from '../constants';
import { createReducer } from '../utils/misc';

const initialState = {
    data: null,
    isFetching: false,
    loaded: false,
};

export default createReducer(initialState, {
    [RECEIVE_PROTECTED_DATA]: (state, payload) =>
        Object.assign({}, state, {
            data: payload.data,
            isFetching: false,
            loaded: true,
        }),
    [FETCH_PROTECTED_DATA_REQUEST]: (state) =>
        Object.assign({}, state, {
            isFetching: true,
        }),
    [GET_EVENTS]: (state) =>
        Object.assign({}, state, {
            isFetching: true,
        }),
    [RECEIVE_EVENTS]: (state, payload) =>
        Object.assign({}, state, {
            events: payload.events,
            isFetching: false,
            loaded: true,
        }),
    [GET_DASHBOARD]: (state) =>
        Object.assign({}, state, {
            isFetching: true,
        }),
    [RECEIVE_DASHBOARD]: (state, payload) =>
        Object.assign({}, state, {
            dashboard: payload.dashboard,
            dashboardLoaded: true,
        })
});
