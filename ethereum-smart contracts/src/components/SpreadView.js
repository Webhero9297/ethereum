import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as actionCreators from '../actions/data';
import { browserHistory } from 'react-router';
import Pusher from 'react-pusher';
import Spread from './events/Spread';

function mapStateToProps(state) {
    return {
        data: state.spread.spread,
        loaded: state.spread.loaded,
    };
}


function mapDispatchToProps(dispatch) {
    return bindActionCreators(actionCreators, dispatch);
}

@connect(mapStateToProps, mapDispatchToProps)
export default class SpreadView extends React.Component {
    componentDidMount() {
        this.fetchData();
    }

    fetchData() {
        const token = this.props.token;
        this.props.getSpread(token, this.props.routeParams.outcome_id)
            .then(() => this.setState({}))
    }

    render() {
        return (
            <section>
                <div className="container">
                    <div className="row">
                        <div className="col-md-12 col-xs-12 col-sm-12">
                            {!this.props.data
                                ? <h1>Loading data...</h1> :
                                <h2>{this.props.data.event.name} | <strong>{this.props.data.outcome.name}</strong></h2>
                            }
                        </div>
                    </div>

                    <div className="row">
                        <div className="col-md-12 col-xs-12 col-sm-12">
                        {!this.props.data
                            ? <h1>Loading data...</h1> :
                            <Spread token={this.props.token} event={this.props.data.event} outcome={this.props.data.outcome} />
                        }
                        </div>
                    </div>
                </div>
                <Pusher
                channel={'outcome-' + this.props.routeParams.outcome_id}
                event="new-bid"
                onUpdate={() => this.fetchData()}
                />
                <Pusher
                channel={'outcome-' + this.props.routeParams.outcome_id}
                event="new-offer"
                onUpdate={() => this.fetchData()}
                />
            </section>
        );
    }
}

SpreadView.propTypes = {
    getSpread: React.PropTypes.func,
    loaded: React.PropTypes.bool,
    data: React.PropTypes.any,
};
