/* eslint camelcase: 0 */

import axios from 'axios';

const tokenConfig = (token) => ({
    headers: {
        'Authorization': token, // eslint-disable-line quote-props
        'Content-type': 'application/json'
    },
});

export function validate_token(token) {
    return axios.post('/api/is_token_valid', {
        token,
    });
}

export function get_github_access() {
    window.open(
        '/github-login',
        '_blank' // <- This is what makes it open in a new window.
    );
}

export function create_user(email, password) {
    return axios.post('/api/create_user', {
        email,
        password,
    });
}

export function get_token(email, password) {
    return axios.post('/api/get_token', {
        email,
        password,
    });
}

export function has_github_token(token) {
    return axios.get('/api/has_github_token', tokenConfig(token));
}

export function data_about_user(token) {
    return axios.get('/api/user', tokenConfig(token));
}

export function get_dashboard(token) {
    return axios.get('/api/dashboard', tokenConfig(token));
}

export function get_events(token) {
    var config = tokenConfig(token);
    config.params = {
        after_date: new Date()
    }
    return axios.get('/api/events', config);
}

export function get_spread(token, outcome_id) {
    var config = tokenConfig(token);
    config.params = {
        'outcome_id': outcome_id
    }
    return axios.get('/api/outcome', config);
}

export function send_bid(token, bid_dict) {
    var config = tokenConfig(token);
    return axios.post('/api/bid/aggregate', bid_dict, config);
}

export function send_offer(token, offer_dict) {
    var config = tokenConfig(token);
    return axios.post('/api/offer', offer_dict, config);
}

export function send_bid_confirm(token, bid_hashes) {
    var config = tokenConfig(token);
    return axios.post('/api/bid/confirm', bid_hashes, config);
}

export function send_offer_confirm(token, offer_hash, tx_hash) {
    var config = tokenConfig(token);
    var offer_dict =  {
        'offer_hash': offer_hash,
        'tx_hash': tx_hash
    };
    return axios.post('/api/offer/confirm', offer_dict, config);
}