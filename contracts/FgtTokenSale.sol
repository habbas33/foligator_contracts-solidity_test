//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./FgtToken.sol";
import "./TokenTimeLock.sol";
import "./Crowdsale.sol";


contract FgtTokenSale is Crowdsale {
  constructor(address _token) Crowdsale(_token){
        rate = 1;
        cap = 50 ether;//50 eth
        openingTime = block.timestamp;
        closingTime = block.timestamp+500;
  }
}
