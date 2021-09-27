// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";


contract Stakeable{
    constructor() {
    }

    struct Stakeholder{
      address user;
      Claimed[] claimed;
      Stake[] user_stakes;
    }

    struct Claimed {
        uint toWithdraw;
        uint claimedDate;
    }

    struct Stake {
      // address user; //Why we need address of user here, when we have it on stakeholder struct?
      uint amount;
      uint since;
    }


    mapping(address => Stakeholder) internal Stakeholders;
    uint256 precision = 100000;


    event Staked(address indexed user, uint256 amount, uint256 timestamp);


    function _addStakeholder(address staker) internal {
        require(staker != address(0), "Cannot stake from zero address");

        Stakeholders[msg.sender].user = staker;
    }

    function _stake(uint256 _amount) internal {
        require(_amount != 0, "Cannot stake zero tokens");
        require(msg.sender != address(0), "Cannot stake from zero address");

        uint256 timestamp = block.timestamp;

        if(Stakeholders[msg.sender].user == address(0) ){
            _addStakeholder(msg.sender);
        }

        Stakeholders[msg.sender].user_stakes.push(Stake({
            // user: msg.sender,
            amount: _amount  * precision,
            since: timestamp
            })
        );

        emit Staked(msg.sender, _amount, timestamp);
    }

    function _claim(uint amount) internal {
        require(Stakeholders[msg.sender].user != address(0), "The user is not a stakeholder yet");

        Stake[] memory userStakes = Stakeholders[msg.sender].user_stakes;

        uint256 toWithdrawSum = 0;
        uint stakedSum = 0;

        for(uint i = 0; i < userStakes.length; i++) {
            if (block.timestamp - userStakes[i].since > 1 days) {
                uint256 APY = 15;
                if (stakedSum > 100) {
                    APY = 16;
                } else if (stakedSum > 1000) {
                    APY = 17;
                } else if (stakedSum > 1500) {
                    APY = 18;
                }

                uint256 availableReward = calculateReward(userStakes[i], APY);
                toWithdrawSum += availableReward;
            }
            stakedSum += userStakes[i].amount;
        }

        require(stakedSum >= amount, "Cannot withdraw more than you own");

        delete Stakeholders[msg.sender].user_stakes;

        if( amount > 0 ) {
            stakedSum -= amount;
            toWithdrawSum += amount;
        }

        if( stakedSum != 0){
            Stakeholders[msg.sender].user_stakes.push(Stake({
                   // user: msg.sender,
                    amount: stakedSum,
                    since: block.timestamp
                })
            );
        }

            Stakeholders[msg.sender].claimed.push(Claimed({
                toWithdraw: toWithdrawSum,
                claimedDate: block.timestamp
            })
        );
    }

    function _withdraw() internal returns(uint256){
        uint256 toWithdrawSum = 0;

        require(Stakeholders[msg.sender].user != address(0), "The user is not a stakeholder yet");
        require(block.timestamp - Stakeholders[msg.sender].claimed[0].claimedDate > 1 days, "Can't withdraw if less than 1 day past after claim");
        require(Stakeholders[msg.sender].claimed.length != 0, "Nothing to withdraw");

        Claimed[] memory _claimed = Stakeholders[msg.sender].claimed;

        delete Stakeholders[msg.sender].claimed;
        for (uint i = 0; i < _claimed.length; i++) {
            if (block.timestamp - _claimed[i].claimedDate > 1 days) {
                toWithdrawSum += _claimed[i].toWithdraw;
            } else {
                Stakeholders[msg.sender].claimed.push(_claimed[i]);
            }
        }

        if(Stakeholders[msg.sender].user_stakes.length == 0 && Stakeholders[msg.sender].claimed.length == 0){
            delete Stakeholders[msg.sender];
        }

        return toWithdrawSum;
    }


    function calculateReward(Stake memory _current_stake, uint APY) internal view returns(uint256){

        uint256 amount = _current_stake.amount;
        
        uint256 diff = (block.timestamp - _current_stake.since) / 1 hours;
        uint256 hoursInYear = 8760;

        return (diff  * amount * APY) / (100 * hoursInYear);
    }

    function _stakingSummary() internal view returns(uint256){
        require(Stakeholders[msg.sender].user != address(0), "The user is not a stakeholder yet");

        uint256 totalStakeAmount;
        Stake[] memory stakes = Stakeholders[msg.sender].user_stakes;

        for (uint256 i = 0; i < stakes.length; i += 1){
           totalStakeAmount += stakes[i].amount;
       }

        //Maybe also calculate possible claimable summary?
        return totalStakeAmount;
    }

}
