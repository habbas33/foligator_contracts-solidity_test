//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "github.com/ConsenSysMesh/openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";

import "./FgtToken.sol";

contract Crowdsale {
    // The token being sold
    IERC20 public immutable token;

    // Address where funds are collected
    address public wallet;
    address public _controllerAddress;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    uint256 public cap;
    uint256 public openingTime;
    uint256 public closingTime;
    address public _owner;
   
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "not contract owner");
        _;
    }

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }
    
    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

    event OwnershipSet(address indexed newOwner);
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ControllerAddressSet(address indexed newControllerAddress);

    // constructor(uint256 _rate, address _wallet, FgtToken _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime) {
    constructor(address _token) {
        // require(rate > 0);
        // require(wallet != address(0));
        // require(address(_token) != address(0));
        // require(cap > 0);
        // require(openingTime >= block.timestamp);
        // require(closingTime >= openingTime);

        // wallet = _wallet;
        

        // uint256 _releaseTime =  block.timestamp+140;
        _owner = msg.sender;
        token = IERC20(_token);
    }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

    receive() external payable {
        buyTokens(msg.sender);
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipSet(newOwner);
        _owner = newOwner;
    }

    function setControllerAddress(address newControllerAddress) public onlyOwner {
        require(newControllerAddress != address(0));
        emit ControllerAddressSet(newControllerAddress);
        _controllerAddress = newControllerAddress;
    }

    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTime || weiRaised >= cap;
    }
   
    function getTimestamp() public view returns (uint) {
        return block.timestamp ;
    }

    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    function addManyToWhitelist(address[] memory _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised + weiAmount;

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        // _updatePurchasingState(_beneficiary, weiAmount);
        payable(_owner).transfer(msg.value);
        // _forwardFunds();
        // _postValidatePurchase(_beneficiary, weiAmount);
    }

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    function withdrawTokens() public {
        require(hasClosed());
        uint256 amount = balances[msg.sender];
        require(amount > 0);
        require(balances[msg.sender] > 0, "you have zero balance");
        balances[msg.sender] = 0;
        _deliverTokens(msg.sender, amount);
  }

    function setTokenOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0),"is address zero");
        token.setOwner(newOwner);
    }
    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) onlyWhileOpen view {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised + _weiAmount <= cap);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(token.mint(_beneficiary, _tokenAmount));
        // token.transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        balances[_beneficiary] = balances[_beneficiary] + _tokenAmount;
        // _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount * rate;
    }

    function _forwardFunds() internal {
        // address payable mywallet = wallet;
        // payable(wallet).transfer(msg.value);
    }


}