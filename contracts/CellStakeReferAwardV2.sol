pragma solidity 0.6.9;

import './interface/ICellNode.sol';
import "./IERC20.sol";

import './interface/IInviteV2.sol';

contract CellStakeReferAwardV2 {
  uint constant PERCENT_BASE = 10000;
  
  uint private referFee   = 500;
  uint private selfFee    = 500;
  uint private referExFee;
  uint private selfExFee;


  // 奖金
  mapping(address => uint) public referAwards;
  mapping(address => uint) public referExAwards;

  mapping(address => bool) public validFarming;

  mapping(address => bool) public exFeeOpen;

  IERC20 private immutable eCell;
  ICellNode private immutable iNode;
  IInviteV2 private immutable iInvite;

  constructor(IERC20 _eCell, ICellNode n, IInviteV2 _invite, address _farming) public {
    eCell = _eCell;
    iNode = n;
    validFarming[_farming] = true;
    iInvite = _invite;
  }

  // 奖励节点
  function award(address user, uint amount, address) external returns (uint) {
    require(validFarming[msg.sender], "caller invalid");
    if (amount == 0) {
      return 0;
    }
    
    address refer = iInvite.refers(user);

    // 节点奖励
    if (referFee > 0) {
      referAwards[refer] += amount * referFee / PERCENT_BASE;
    }

    if (referExFee > 0) {
      referExAwards[refer] += amount * referExFee / PERCENT_BASE;
    }

    if (selfFee > 0) {
      referAwards[user] += amount * selfFee / PERCENT_BASE;
    }

    if (selfExFee > 0) {
      referExAwards[user] += amount * selfExFee / PERCENT_BASE;
    }

    return 0;
  }  

  function getFee() external view returns (uint, uint) {
      return (referFee, selfFee);
    }

  function setFee(uint _referFee, uint _selfFee) external {
    require(iNode.owner() == msg.sender, "no permission");
    require(_referFee < PERCENT_BASE && _selfFee < PERCENT_BASE , "invalid number");
    referFee = _referFee;
    selfFee = _selfFee;
  }


  function getExFee() external view returns(uint, uint) {
    return (referExFee, selfExFee);
  }

  function setExFee(uint _referExFee, uint _selfExFee) external {
    require(iNode.owner() == msg.sender, "no permission");
    require(_referExFee < PERCENT_BASE && _selfExFee < PERCENT_BASE , "invalid number");

    referExFee = _referExFee;
    selfExFee = _selfExFee;
  }

  function getReferAwards(address user) external view returns(uint, uint) {
    return (referAwards[user], referExAwards[user]);
  }
  
  function getExFeeOpen(address[] memory users) external view returns(bool[] memory opens) {
    uint len = users.length;
    opens = new bool[](len);
    for (uint i = 0; i < users.length; i++) {
      opens[i] = exFeeOpen[users[i]];
    }
  }

  function setExFeeOpen(address[] memory users, bool enable) external {
    require(iNode.owner() == msg.sender, "no permission");
    for (uint i = 0; i < users.length; i++) {
      exFeeOpen[users[i]] = enable;
    }
  }

  function setFarming(address farming, bool enable) external {
    require(iNode.owner() == msg.sender, "no permission");
    validFarming[farming] = enable;
  }


  function wdReferAwards(address to) external {
    if (!exFeeOpen[msg.sender]) {
      eCell.transfer(to, referAwards[msg.sender]); 
      referAwards[msg.sender] = 0;
    } else {
      eCell.transfer(to, referAwards[msg.sender] + referExAwards[msg.sender]); 
      referAwards[msg.sender] = 0;
      referExAwards[msg.sender] = 0;
    }
  }

  // 管理员赎回
  function wd(uint amount) external {
    require(iNode.owner() == msg.sender, "no permission");
    eCell.transfer(msg.sender, amount);
  }

}