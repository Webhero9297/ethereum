import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import { Router, Redirect, browserHistory } from 'react-router';
import injectTapEventPlugin from 'react-tap-event-plugin';
import { syncHistoryWithStore } from 'react-router-redux';

import { PUSHER_KEY } from './constants/index';
import configureStore from './store/configureStore';
import routes from './routes';
import './style.scss';
import Pusher from 'pusher-js';
import { setPusherClient } from 'react-pusher';

require('expose?$!expose?jQuery!jquery');
require('bootstrap-webpack');

injectTapEventPlugin();
const store = configureStore();
const history = syncHistoryWithStore(browserHistory, store);

Pusher.logToConsole = true;

const pusherClient = new Pusher(PUSHER_KEY, {
  encrypted: true
});

setPusherClient(pusherClient);

ReactDOM.render(
    <Provider store={store}>
        <Router history={history}>
            {<Redirect from="/" to="main" />}
            {routes}
        </Router>
    </Provider>,
    document.getElementById('root')
);
