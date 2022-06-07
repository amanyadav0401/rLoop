//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RLoopStaking is Ownable {
    IERC20 internal token;
    uint256 public rewardPercent;

    struct UserTransaction {
        uint256 amount;
        uint256 lockedUntil;
        uint256 time;
        uint rewardAPY;
        bool rewardClaimed;
       
    }
    struct Transaction {
        uint256 txNo;
        uint256 totalAmount;
        mapping(uint256 => UserTransaction) stakingPerTx;
    }

    mapping(address => Transaction) public userTx;
    mapping(uint256 => uint256) public stakePeriodRewardPercent;

    event StakeDeposit(uint256 amount, uint256 time, uint256 lockedUntil);

    constructor(IERC20 _token) {
        token = _token;
    }

    function redeemTokens() public onlyOwner {
        uint amount = token.balanceOf(address(this));
        token.transfer(msg.sender,amount);
    }

    function addStake(uint256 _time, uint256 _amount) internal {
        Transaction storage txNumber = userTx[msg.sender];
        token.transferFrom(msg.sender, address(this), _amount);
        txNumber.txNo++;
        txNumber.totalAmount += _amount;
        txNumber.stakingPerTx[txNumber.txNo].amount = _amount;
        txNumber.stakingPerTx[txNumber.txNo].time = _time;
        txNumber.stakingPerTx[txNumber.txNo].lockedUntil =
            block.timestamp +
            _time;
        txNumber.stakingPerTx[txNumber.txNo].rewardAPY = stakePeriodRewardPercent[_time];
    }

    function stake(uint256 _time, uint256 _amount) public {
        require(_amount != 0, "Null Amount");
        require(stakePeriodRewardPercent[_time] != 0, "Time not specified!");
        addStake(_time, _amount);
        emit StakeDeposit(
            _amount,
            block.timestamp,
            userTx[msg.sender].stakingPerTx[userTx[msg.sender].txNo].lockedUntil
        );
    }

    function claimableReward(uint256 _txNo) public view returns (uint256) {
        Transaction storage txNumber = userTx[msg.sender];
        uint256 amount = txNumber.stakingPerTx[_txNo].amount;
        uint256 lockedTime = txNumber.stakingPerTx[_txNo].lockedUntil;
        if (
            block.timestamp > lockedTime &&
            txNumber.stakingPerTx[_txNo].rewardClaimed == false
        ) {
            uint256 reward = (amount *txNumber.stakingPerTx[_txNo].rewardAPY) /
                10000;
            return reward;
        } else return 0;
    }

     function claimReward(uint256 _txNo) public {
        Transaction storage txNumber = userTx[msg.sender];
        uint256 reward = claimableReward(_txNo);
        uint256 amount = txNumber.stakingPerTx[_txNo].amount;
        require(
            txNumber.stakingPerTx[_txNo].rewardClaimed != true,
            "Rewards already claimed!"
        );
        txNumber.totalAmount -= amount;
        token.transfer(msg.sender, reward + amount);
        txNumber.stakingPerTx[_txNo].rewardClaimed = true;
    }
    // Function to set staking time and reward percent, changing reward percent for existing staking time will not change the 
    // APY of already staked amount in the past, same for time.
    // 100 denotes 1 percent.
    function setTimeRewardPercent(uint256 time, uint256 newRewardPercent)
        public
        onlyOwner
    {
        stakePeriodRewardPercent[time] = newRewardPercent;
    }

    function checkTransaction(uint _txNo) public view returns(UserTransaction memory){
        return userTx[msg.sender].stakingPerTx[_txNo];
    }
}
