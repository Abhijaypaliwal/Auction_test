// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT

//goerli : 0x4b7c27aa9636E531D035cFdB5154f5d555BFe2Ed
//optimism: 0x36Ed385413172840dA60587Fa839c6db7A5F1f55
pragma solidity ^0.8.19;

import "./ERC20.sol";

contract GLDToken is ERC20 {
    constructor() public ERC20("Gold", "GLD") {
    }

}

    
