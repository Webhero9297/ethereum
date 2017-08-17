import React from 'react';
import {
  Table,
  TableBody,
  TableHeader,
  TableHeaderColumn,
  TableRow,
  TableRowColumn,
} from 'material-ui/Table';
import TextField from 'material-ui/TextField';
import Dialog from 'material-ui/Dialog';
import NumberInput from 'material-ui-number-input';
import FlatButton from 'material-ui/FlatButton';
import RaisedButton from 'material-ui/RaisedButton';
import CircularProgress from 'material-ui/CircularProgress';
import { ResponsiveContainer, 
    BarChart, Bar, XAxis, YAxis,
    CartesianGrid, Tooltip, Legend } from 'recharts';
import * as actionCreators from '../../actions/data';
import * as blockchainCreators from '../../actions/blockchain';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

function mapStateToProps(state) {
    return {
        offer_hash: state.spread.offer_hash,
        bid_hashes: state.spread.bid_hashes,
        offer_tx_hash: state.blockchain.contractHash,
        bid_tx_hashes: state.blockchain.transactionHash
    };
}


function mapDispatchToProps(dispatch) {
    return bindActionCreators(actionCreators, dispatch);
}

function mapBlockchainDispatch(dispatch) {
    return bindActionCreators(blockchainCreators, dispatch);
}

@connect(mapStateToProps, mapBlockchainDispatch)
@connect(mapStateToProps, mapDispatchToProps)
class Spread extends React.Component { // eslint-disable-line react/prefer-stateless-function
    
    updateTables() {
        var offerTemp = {};
        if (!this.props.outcome.offers) {
            return;
        }
        this.props.outcome.offers.map((offer) => {
            if (!offerTemp[offer.odds]) {
                offerTemp[offer.odds] = {
                    offers: 1,
                    riding_value: 0,
                    available_coverage: offer.remaining_coverage
                }
            } else {
                offerTemp[offer.odds].offers++;
                offerTemp[offer.odds].available_coverage += offer.remaining_coverage;
            }
            offer.bids.map((bid) => {
                offerTemp[offer.odds].riding_value += bid.value;
            })
        });
        this.offerHistogram = [];
        var id = 0;
        Object.keys(offerTemp).map((key) => {
            this.offerHistogram.push({
                id: id,
                value: key,
                'Available Offers': offerTemp[key].offers,
                'Available Coverage': offerTemp[key].available_coverage,
                'Riding Value': offerTemp[key].riding_value
            });
            id++;
        })
        this.offerTemp = null;
        this.setState({
            offerHistogram: this.offerHistogram
        });
    }

    componentWillUnmount() {
        this.setState({
            offerHistogram: null
        })
    }

    componentDidMount() {
        this.state = {
            open: false,
            canBid: false,
            canOffer: false
        };

        this.min_bid = 0.0001;
        this.updateTables();
        
    }

    componentWillReceiveProps(nextProps) {
        this.updateTables();
    }
    
    handleOpen = () => {
        this.setState({open: true, canBid: false});
    };

    handleClose = (go) => {
        var self = this;
        if (go) {
            this.setState({globalLoading: true});
            this.setState({findingBids: true});
            this.props.sendBid(this.props.token, {
                outcome_id: this.props.outcome.id,
                odds: this.state.selectedOffer.value,
                amount: this.state.bidValue
            }).then(() => {
                this.setState({findingBids: false, makingBids: true});
                this.props.makeBids(self.props.bid_hashes.bids, self.state.bidValue).then(() => {
                    this.setState({makingBids: false, confirmingBids: true});
                    this.props.confirmBids(self.props.token, 
                    self.props.bid_hashes.bids, self.props.bid_tx_hashes).then(() => {
                        this.setState({open: false, confirmingBids: false,  globalLoading: false});
                    });
                });
            });
        } else {
            this.setState({open: false});
        }
    };

    handleOfferOpen = () => {
        this.setState({offerOpen: true, offerOdds: "1", canOffer: false, offerValue: '0'});
    };

    handleOfferClose = (go) => {
        var self = this;
        if (go) {
            this.setState({globalLoading: true});
            this.setState({sendingOffer: true});
            var payload = {
                outcome_id: this.props.outcome.id,
                coverage: this.state.offerValue,
                odds: this.state.offerOdds,
            };
            self.props.sendOffer(self.props.token, payload).then(() => {
                this.setState({sendingOffer: false, deployingOffer: true});
                self.props.makeOffer(self.state.offerOdds, self.state.offerValue,
                    self.props.offer_hash).then(() => {
                    this.setState({deployingOffer: false, confirmingOffer: true});
                    self.props.confirmOffer(self.props.token,
                        self.props.offer_hash, self.props.offer_tx_hash.deployedOffer).then(() => {
                        self.setState({offerOpen: false, confirmingOffer: false, globalLoading: false});
                    });
                });
            });
        } else {
            self.setState({offerOpen: false});
        }
    };

    chartHeight() {
        return window.innerHeight / 3;
    }

    chartWidth() {
        return this.refs.chartParent.clientWidth / 3 - 5;
    }

    showBidModal = (offer) => {
        this.setState({
            selectedOffer: offer
        });
        this.handleOpen();
    }

    render() {
        var self = this;

        const actions = this.state && [
            <FlatButton
                label="Cancel"
                primary={true}
                onTouchTap={() => this.handleClose(false)}
            />,
            <FlatButton
                label="Bid"
                primary={true}
                disabled={!this.state.canBid}
                keyboardFocused={true}
                onTouchTap={() => this.handleClose(true)}
            />
        ];
        const offerActions = this.state && [
            <FlatButton
                label="Cancel"
                primary={true}
                onTouchTap={() => this.handleOfferClose(false)}
            />,
            <FlatButton
                label="Offer"
                primary={true}
                disabled={!this.state.canOffer}
                keyboardFocused={true}
                onTouchTap={() => this.handleOfferClose(true)}
            />
        ];
        return (
            <div className="container">
                <div className="row">
                    <div className="col-md-12 recharts-override" ref="chartParent">
                            {(self.state && self.state.offerHistogram) &&
                            <ResponsiveContainer width="33%" height={this.chartHeight()}>
                            <BarChart data={self.state.offerHistogram}>
                            <XAxis dataKey="value"/>
                            <YAxis/>
                            <CartesianGrid strokeDasharray="3 3"/>
                            <Tooltip />
                            <Legend />
                            <Bar type="monotone" dataKey="Available Offers" fill="#8884d8" activeDot={{r: 8}} />
                            </BarChart>
                            </ResponsiveContainer>
                            }
                            {(self.state && self.state.offerHistogram) &&
                            <ResponsiveContainer width="33%" height={this.chartHeight()}>
                            <BarChart data={self.state.offerHistogram}>
                            <XAxis dataKey="value"/>
                            <YAxis/>
                            <CartesianGrid strokeDasharray="3 3"/>
                            <Tooltip />
                            <Legend />
                            <Bar type="monotone" dataKey="Available Coverage" fill="#516482" activeDot={{r: 8}} />
                            </BarChart>
                            </ResponsiveContainer>
                            }
                            {(self.state && self.state.offerHistogram) &&
                            <ResponsiveContainer width="33%" height={this.chartHeight()}>
                            <BarChart data={self.state.offerHistogram}>
                            <XAxis dataKey="value"/>
                            <YAxis/>
                            <CartesianGrid strokeDasharray="3 3"/>
                            <Tooltip />
                            <Legend />
                            <Bar type="monotone" dataKey="Riding Value" fill="#82ca9d" activeDot={{r: 8}} />
                            </BarChart>
                            </ResponsiveContainer>
                            }
                    </div>
                    <div className="col-md-12">
                        <div className="row">
                            <div className="col-md-12">
                                <Table>
                                <TableHeader
                                adjustForCheckbox={false}
                                displaySelectAll={false}
                                >
                                    <TableRow>
                                        <TableRowColumn>Odds</TableRowColumn>
                                        <TableRowColumn>Available Coverage</TableRowColumn>
                                        <TableRowColumn>Total Riding Bets</TableRowColumn>
                                    </TableRow>
                                </TableHeader>
                                <TableBody displayRowCheckbox={false} showRowHover={true}>
                                { self.state && self.state.offerHistogram.map((offer) => {
                                    return (
                                        <TableRow key={offer.id} className="cursor-pointer" onMouseUp={() => { this.showBidModal(offer)}}>
                                            <TableRowColumn>
                                                {offer.value}:1
                                                </TableRowColumn>
                                            <TableRowColumn>{offer['Available Coverage']} ETH</TableRowColumn>
                                            <TableRowColumn>{offer['Riding Value']} ETH</TableRowColumn>
                                        </TableRow>
                                    )
                                })}
                                </TableBody>
                                </Table>
                            </div>
                            <br />
                            <div className="col-md-12">
                                <p>Click a row ot make a bid, or...</p>
                                <RaisedButton
                                    label="Make offer"
                                    primary={true}
                                    onClick={() => { self.handleOfferOpen() }}
                                />
                            </div>
                        </div>
                    </div>
                </div>
                {/*Bid Dialog*/}
                { self.state && self.state.selectedOffer && <Dialog
                    title={"Place bid at " + this.state.selectedOffer.value + ":1 odds?"}
                    actions={!self.state.globalLoading && actions}
                    modal={true}
                    open={this.state.open}
                    onRequestClose={this.handleClose}
                >
                    {self.state.globalLoading ? 
                    <div className="centerify">
                        <div style={{paddingBottom: "5px"}}>
                            <CircularProgress size={80} thickness={5} />
                        </div>
                        <div>
                            { self.state.findingBids && <p>Compiling Bid...</p>}
                            { self.state.makingBids && <p>Placing Bid...</p>}
                            { self.state.confirmingBids && <p>Confirming Bid...</p>}
                        </div>
                    </div> :
                    <div>
                    You are betting that {this.props.outcome.name} during {this.props.event.name} on {this.props.event.start_date}
                    <br />
                    <form>
                        <NumberInput 
                        errorText={self.state.canBid && "Please enter a valid number between min and max"}
                        onError={() => {self.setState({canBid: false})}}
                        onValid={(value) => {self.setState({canBid: true, bidValue: value})}}
                        strategy="allow"
                        defaultValue={self.min_bid}
                        min={self.min_bid}
                        max={this.state.selectedOffer['Available Coverage']}
                        floatingLabelText={"Bid Amount: MAX " + self.state.selectedOffer['Available Coverage']}
                        />
                    </form>
                    <br />
                    <br />
                    NOTE: bids are final once placed and cannot be undone.
                    </div> }
            </Dialog> }
            {/*Offer Dialog*/}
            { self.state && self.state.offerOpen && <Dialog
                    title={"Make an offer"}
                    actions={!self.state.globalLoading && offerActions}
                    modal={true}
                    open={self.state.offerOpen}
                    onRequestClose={this.handleOfferClose}
                >
                    {self.state.globalLoading ? 
                    <div className="centerify">
                        <div style={{paddingBottom: "5px"}}>
                            <CircularProgress size={80} thickness={5} />
                        </div>
                        <div>
                            { self.state.sendingOffer && <p>Sending Offer...</p>}
                            { self.state.deployingOffer && <p>Deploying Offer...</p>}
                            { self.state.confirmingOffer && <p>Confirming Offer...</p>}
                        </div>
                    </div> :
                    <div>
                    You are offering on {this.props.outcome.name} during {this.props.event.name} on {this.props.event.start_date}
                    <br />
                    <form>
                        <div>
                        <NumberInput 
                        errorText={!self.state.canOffer && "Please enter a valid number between min and max"}
                        onError={() => {self.setState({canOffer: false})}}
                        onValid={(value) => {self.setState({canOffer: true, offerValue: value})}}
                        strategy="allow"
                        min={self.min_bid}
                        max={Infinity}
                        floatingLabelText={"Offer Amount"}
                        />
                        </div>
                        <br />
                        <div>
                        <NumberInput 
                        errorText={!self.state.canOffer && "Please enter a valid number."}
                        onError={() => {self.setState({canOffer: false})}}
                        onValid={(value) => {self.setState({canOffer: true, offerOdds: value})}}
                        strategy="allow"
                        min={1}
                        max={Infinity}
                        floatingLabelText={"Odds"}
                        />
                        </div>
                    </form>
                    <br />
                    NOTE: offers are final once placed and cannot be undone.
                    </div>}
            </Dialog> }
            </div>
        )
    }
}

Spread.propTypes = {
    event: React.PropTypes.any,
    outcome: React.PropTypes.any,
    token: React.PropTypes.any
};

export default Spread;
