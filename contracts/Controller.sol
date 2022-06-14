//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FgtToken.sol";
import "./TokenTimeLock.sol";

contract Controller {
    // The token being sold
    IERC20 public immutable token;

    bool initialMintAvailable;
    // Address where funds are collected
    address public _admin;
    address public _tokenSaleContract;
    address public _reserveAddress;
    address public _liquidityAddress;
    address public _marketingAddress;
    address public _teamAddress;

    mapping(address => uint256) public _fgt_holdings;
    
    modifier onlyAdmin() {
        require(msg.sender == _admin, "not contract admin");
        _;
    }

    event AdminSet(address indexed newAdmin);
    event ReserveAddressSet(address indexed newReserveAddress);
    event LiquidityAddressSet(address indexed newLiquidityAddress);
    event MarketingAddressSet(address indexed newMarketingAddress);
    event TeamAddressSet(address indexed newTeamAddress);
    event FgtClaimed(address indexed , uint256 amount);
    
    constructor(address _token, address _tokenSaleContractAddr) {
        _admin = msg.sender;
        _tokenSaleContract = _tokenSaleContractAddr;
        _reserveAddress = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
        _liquidityAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        _marketingAddress = 0x583031D1113aD414F02576BD6afaBfb302140225;
        _teamAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        token = IERC20(_token);
        initialMintAvailable = true;
        
    }
    
    function getFgtHolding() public view returns (uint256) {
        return _fgt_holdings[msg.sender];
    }

    function getFgtHoldingOf(address _account) public view returns (uint256) {
        return _fgt_holdings[_account];
    }

    function initialMint() public onlyAdmin {
        require(initialMintAvailable == true, "already minted");
        require(token.mint(address(this), 74000000));
        _fgt_holdings[_tokenSaleContract] = 50000000;
        _fgt_holdings[_reserveAddress] = 2000000;
        _fgt_holdings[_liquidityAddress] = 20000000;
        _fgt_holdings[_marketingAddress] = 2000000;
        _fgt_holdings[_teamAddress] = 0;
        initialMintAvailable = false;
    }
    
  // -----------------------------------------
  // Controller external interface
  // -----------------------------------------
    function tokenSaleClaim() external onlyAdmin{
        _claimFgt(_tokenSaleContract);
    }

    function claim() external {
        _claimFgt(msg.sender);
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit AdminSet(newAdmin);
        _admin = newAdmin;
    }
    
    function setReserveAddress(address newReserveAddress) public onlyAdmin {
        require(newReserveAddress != address(0));
        emit ReserveAddressSet(newReserveAddress);
        _reserveAddress = newReserveAddress;
    }

    function setLiquidityAddress(address newLiquidityAddress) public onlyAdmin {
        require(newLiquidityAddress != address(0));
        emit LiquidityAddressSet(newLiquidityAddress);
        _liquidityAddress = newLiquidityAddress;
    }

    function setMarketingAddress(address newMarketingAddress) public onlyAdmin {
        require(newMarketingAddress != address(0));
        emit MarketingAddressSet(newMarketingAddress);
        _marketingAddress = newMarketingAddress;
    }

    function setTeamAddress(address newTeamAddress) public onlyAdmin {
        require(newTeamAddress != address(0));
        emit TeamAddressSet(newTeamAddress);
        _teamAddress = newTeamAddress;
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    function _claimFgt(address _beneficiary) internal {
        uint256 _tokenAmount = _fgt_holdings[_beneficiary];
        require(_tokenAmount > 0, "no tokens to claim");
        _fgt_holdings[_beneficiary] = 0;
        token.transfer(_beneficiary, _tokenAmount);
        emit FgtClaimed(_beneficiary, _tokenAmount);
    }
}
