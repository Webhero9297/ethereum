import React from 'react';
import {
  Table,
  TableBody,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
import { browserHistory } from 'react-router';

class OutcomeTable extends React.Component { // eslint-disable-line react/prefer-stateless-function
    
    dispatchNewRoute(route) {
        browserHistory.push(route);
    }

    render() {
        return this.props.event.outcomes.length ? (
            <Table
                selectable={false}
                >
                <TableHeader
                adjustForCheckbox={false}
                displaySelectAll={false}
                >
                    <TableRow>
                        <TableRowColumn>Outcome</TableRowColumn>
                        <TableRowColumn>Average Odds</TableRowColumn>
                        <TableRowColumn>Total Riding Bets</TableRowColumn>
                    </TableRow>
                </TableHeader>
                <TableBody displayRowCheckbox={false}>
                { this.props.event.outcomes.map((outcome) => {
                    return (
                        <TableRow key={outcome.id} className="cursor-pointer">
                            <TableRowColumn>
                                <a onClick={() => { this.dispatchNewRoute('spread/' + outcome.id )}}>{outcome.name}</a>
                                </TableRowColumn>
                            <TableRowColumn>{outcome.average_odds}:1</TableRowColumn>
                            <TableRowColumn>{outcome.total_riding} BTC</TableRowColumn>
                        </TableRow>
                    )
                })}
                </TableBody>
            </Table>
        ) : <p>There are no outcomes avaialble for this event.</p>;
    }
}

OutcomeTable.propTypes = {
    event: React.PropTypes.any
};

export default OutcomeTable;
