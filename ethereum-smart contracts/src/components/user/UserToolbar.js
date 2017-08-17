import React from 'react';
import IconMenu from 'material-ui/IconMenu';
import FlatButton from 'material-ui/FlatButton';
import RaisedButton from 'material-ui/RaisedButton';
import NavigationExpandMoreIcon from 'material-ui/svg-icons/navigation/expand-more';
import MenuItem from 'material-ui/MenuItem';
import {Toolbar, ToolbarGroup, ToolbarSeparator, ToolbarTitle} from 'material-ui/Toolbar';
import Avatar from 'material-ui/Avatar';
import Badge from 'material-ui/Badge';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as actionCreators from '../../actions/data';


function mapStateToProps(state) {
    return {
        user: state.data.dashboard
    };
}

function mapDispatchToProps(dispatch) {
    return bindActionCreators(actionCreators, dispatch);
}

@connect(mapStateToProps, mapDispatchToProps)
class UserToolbar extends React.Component { // eslint-disable-line react/prefer-stateless-function
   
    componentDidMount() {
        var web3 = window.web3;
        if (web3) {
            var baseWallet = web3.eth.accounts[0];
            var wallet = baseWallet ? baseWallet.substring(0, 8) : null;
            this.setState({
                'wallet': wallet
            });
            if (wallet) {
                web3.eth.getBalance(baseWallet, 'latest', (err, res) => {
                    var ether = web3.fromWei(res.toNumber(), 'ether');
                    this.setState({
                        balance: ether
                    })
                });
            }
        } else {
            this.setState({
                wallet: null
            });
        }
        this.fetchData();
    }


    fetchData() {
        this.props.getDashboard(this.props.token)
    }

    render() {
        var self = this;
        return self.props.user && self.state && window.web3 ? (
            <Toolbar>
                <ToolbarGroup>
                    {self.props.user.avatar_url &&
                        <Avatar src={self.props.user.avatar_url} />}
                    <ToolbarTitle text={self.props.user.handle || self.props.user.email} />
                </ToolbarGroup>
                <ToolbarGroup>
                    <ToolbarSeparator />
                </ToolbarGroup>
                <ToolbarGroup>
                    <IconMenu
                        iconButtonElement={
                        <FlatButton label="Offers"
                            labelPosition="before"
                            icon={<Badge style={{verticalAlign: "text-top", bottom: "5px"}}
                            badgeContent={self.props.user.offers.length}
                            primary={self.props.user.offers.length > 0}></Badge>}
                        />}>
                        {self.props.user.offers.length ? self.props.user.offers.map((offer) => {
                            return (<MenuItem key={offer.id} primaryText={offer.outcome.name + ' | ' + offer.coverage + ' @ ' + offer.odds} />);
                        }) : <MenuItem primaryText="No active offers." />}
                    </IconMenu>
                </ToolbarGroup>
                <ToolbarGroup>
                    <IconMenu
                        iconButtonElement={
                        <FlatButton label="Bids"
                            labelPosition="before"
                            icon={<Badge style={{verticalAlign: "text-top", bottom: "5px"}}
                            badgeContent={self.props.user.bids.length}
                            primary={self.props.user.bids.length > 0}></Badge>}
                        />}>
                        {self.props.user.bids.length ? self.props.user.bids.map((bid) => {
                            return (<MenuItem key={bid.id} primaryText={bid.name} />);
                        }) : <MenuItem primaryText="No active bids." />}
                    </IconMenu>
                </ToolbarGroup>
                <ToolbarGroup>
                    <RaisedButton label="Dashboard" primary={true} />
                </ToolbarGroup>
                <ToolbarGroup>
                    <ToolbarTitle style={{'paddingRight': "0"}}
                    text={self.state.wallet || "No Wallet"} />
                    <ToolbarSeparator style={{margin: "0 12px 0 12px"}}/>
                    <ToolbarTitle text={(this.state.balance ? this.state.balance : "0.000") + " ETH"} />
                </ToolbarGroup>
            </Toolbar>
        ) : <Toolbar>
            <ToolbarGroup>
                <ToolbarTitle text="You don't have Ethereum active in your browser." />
                <RaisedButton label="Learn More" primary={false} onClick={() =>  window.open("https://www.ethereum.org/")} />
                <RaisedButton label="Install" primary={true} onClick={() =>  window.open("https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=en")} />
            </ToolbarGroup>
            </Toolbar>
    }
}

UserToolbar.propTypes = {
    user: React.PropTypes.any,
    token: React.PropTypes.any,
    getDashboard: React.PropTypes.func
};

export default UserToolbar;