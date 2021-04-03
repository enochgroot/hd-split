// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./split.sol";

contract User {
    constructor () {
        // do nothing
    }

    balanceOfETH() {
        return address(this).balance;
    }
}

contract SplitTest is DSTest {
    HDSplit split;
    User alice;
    User bob;
    User carol;

    function setUp() public {
        alice  = new User();
        bob    = new User();
        carol  = new User();

        split  = new HDSplit([alice, bob, carol], [5000, 2500, 2500]);

        // magic up some ETH

        // magic up some DAI
    }

    function testPushETH() public {
        assertEq(alice.balanceOfETH(), 0);
        assertEq(bob.balanceOfETH(), 0);
        assertEq(carol.balanceOfETH(), 0);

        drop.mint(_addr, _uri, NONCE, _addr, 0);

        assertEq(drop.totalSupply(), 1);
    }
}