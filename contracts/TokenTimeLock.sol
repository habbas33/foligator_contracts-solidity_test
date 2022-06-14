//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FgtToken.sol";

library SafeERC20{
  function safeTransfer(FgtToken token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(FgtToken token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(FgtToken token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract TokenTimeLock {
    using SafeERC20 for FgtToken;

    FgtToken public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    constructor(FgtToken _token, address _beneficiary, uint256 _releaseTime) {
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    function release() public {
        require(block.timestamp >= releaseTime);

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }

}