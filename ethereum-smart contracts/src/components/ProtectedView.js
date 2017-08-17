import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as actionCreators from '../actions/data';
import EventCard from './events/EventCard';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import { browserHistory } from 'react-router';

function mapStateToProps(state) {
    return {
        data: state.data,
        events: state.events,
        token: state.auth.token,
        loaded: state.data.loaded,
        dashbaordLoaded: state.data.dashbaordLoaded,
        isFetching: state.data.isFetching,
    };
}


function mapDispatchToProps(dispatch) {
    return bindActionCreators(actionCreators, dispatch);
}

@connect(mapStateToProps, mapDispatchToProps)
export default class ProtectedView extends React.Component {
    componentDidMount() {
        this.fetchData();
    }


    fetchData() {
        const token = this.props.token;
        this.props.fetchProtectedData(token);
        this.props.getEvents(token);
    }

    render() {
        return (
            <section>
                <div className="container">
                    <div className="row">
                        <div className="col-md-12 col-xs-12 col-sm-12">
                        {!this.props.loaded
                            ? <h1>Loading data...</h1>
                            :
                            <div>
                                { this.props.data.events && 
                                this.props.data.events.map((event) => {
                                    return (
                                        <EventCard key={event.id} event={event} />
                                    )
                                })
                                }
                            </div>
                        }
                        </div>
                    </div>
                </div>
            </section>
        );
    }
}

ProtectedView.propTypes = {
    fetchProtectedData: React.PropTypes.func,
    getEvents: React.PropTypes.func,
    loaded: React.PropTypes.bool,
    dashbaordLoaded: React.PropTypes.bool,
    userName: React.PropTypes.string,
    data: React.PropTypes.any,
    token: React.PropTypes.string,
};
