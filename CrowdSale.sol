// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// interface IToken{
//     function mint(address to, uint256 value) external;
// }

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ITERC20.sol";

contract CrowdFunding is Context{
    using SafeMath for uint256;
    uint256 minimumTarget = 100000000000000000000000;
    address private _owner;
    address private _tradingContract;
    mapping(address => uint256) private timestamps;
    mapping(address => uint256) private poolShare;
    mapping(address => uint256) private earnings;
    uint256 share;
    address[] subscribers;
    uint256 poolTotal = 0;
    ITERC20 oEdge;
    uint256 rate = 1;
    bool isRedeemOpen;
    bool isRefundStarted = false;

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(ITERC20 _oEdge, bool _redeemOption, address _contract,uint256 _share ){
        oEdge = _oEdge;
        isRedeemOpen = _redeemOption;
        _owner = _msgSender();
        _tradingContract = _contract;
        share =_share;
    }

    function provideLiquidity() public payable{
        require(_msgSender()!=address(0),"CrowdFundingException: Null address not allowed!");
        if(poolShare[_msgSender()] == 0){
            require(msg.value >= 1 ether, "CrowdFundingException: Value must be greater than one BNB");
            subscribers.push();
            poolShare[_msgSender()] = msg.value;
            timestamps[_msgSender()] = block.timestamp;
            poolTotal += msg.value;
            oEdge.mint(_msgSender(),(msg.value).mul(rate));
        }else{
            uint256 value =  poolShare[_msgSender()];
            require(msg.value.add(value) >= 1 ether, "CrowdFundingException: Total value must be greater than one BNB");
            poolShare[_msgSender()] = msg.value.add(value);
            timestamps[_msgSender()] = block.timestamp;
            poolTotal += msg.value;
            oEdge.mint(_msgSender(),(msg.value).mul(rate));
        }
    }

    /*
    *
    * To be called by Contract Owner
    *
    */

    function startRefund() public virtual onlyOwner{
        require(minimumTarget > poolTotal,"CrowdFundingException: Target Acheived!");
        isRefundStarted = true;
    }
    // launch Project and remove ownership
    function launchProject() public virtual onlyOwner{
        require(minimumTarget < poolTotal,"CrowdFundingException: Target Acheived!");
        _owner = address(0);
    }

    /*
    *
    * To be called by Subscribers
    *
    */
    function refund() public virtual{
        require(isRefundStarted,"CrowdFundingException: Refund not valid!");
        address payable subscriber = payable(_msgSender());
        subscriber.transfer(poolShare[_msgSender()].add(earnings[_msgSender()]));
        
    } 

    function redeem() public virtual{
         require(isRedeemOpen,"CrowdFundingException: Redeem is not opened yet!");
        address payable subscriber = payable(_msgSender());
        subscriber.transfer(poolShare[_msgSender()].add(earnings[_msgSender()]));
    }

    function getPoolShare() public view returns (uint256) {
        return poolShare[_msgSender()];
    }

    function viewEarning() public view returns (uint256)  {
        return earnings[_msgSender()];
    }
    function getPoolSharePercent() public view returns (uint256)  {
        return poolShare[_msgSender()].div(poolTotal).mul(1000000000000000000);
    }

    /*
    *
    * To be called by Trading Contract
    *
    */

    function getSubscribers() external view returns (address[] memory)  {
        require(_tradingContract == _msgSender(),"CrowdFundingException: Action not Allowed");
        return subscribers;
    }

    function getPoolShare(address subcriber) external view returns (uint256){
        require(_tradingContract == _msgSender(),"CrowdFundingException: Action not Allowed");
        return poolShare[subcriber].div(poolTotal); 
    }
    function setEarning(address subcriber,uint256 value) external virtual payable {
        require(_tradingContract == _msgSender(),"CrowdFundingException: Action not Allowed");
        earnings[subcriber] = earnings[subcriber].add(value);       
    }
    // Transfer Gas Fees to Bot controller address to be called by trading bot only;
    function transferGasFees(address payable botController,uint256 value) external {
        require(_tradingContract == _msgSender(),"CrowdFundingException: Action not Allowed");
        botController.transfer(value);
    }
}