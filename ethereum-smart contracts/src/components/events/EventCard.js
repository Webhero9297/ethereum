import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import {Card, CardActions, CardHeader, CardMedia, CardTitle, CardText} from 'material-ui/Card';
import FlatButton from 'material-ui/FlatButton';
import OutcomeTable from './OutcomeTable';
import baseball from '../../img/baseball.jpg';
import mlb_avatar from '../../img/mlb_avatar.png';

class EventCard extends React.Component { // eslint-disable-line react/prefer-stateless-function
    render() {
        return (
            <Card containerStyle={ {margin: "10px 0 10px 0"} }>
                <CardHeader
                    title="Major League Baseball"
                    avatar={mlb_avatar}
                />
                <CardMedia
                    /*overlay={<CardTitle title="{this.props.event.outcomes.length} title"
                             subtitle="{this.props.event.total_riding}BTC riding." />}*/
                >
                <img width="100%" src={baseball} />
                </CardMedia>
                <CardTitle title={this.props.event.name} subtitle={this.props.event.start_date}/>
                <CardActions>
                    <OutcomeTable event={this.props.event} />
                </CardActions>
            </Card>
        );
    }
}

EventCard.propTypes = {
    event: React.PropTypes.any
};

export default EventCard;
