// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import "./split.sol";

contract User {

    constructor () {
        // do nothing
    }

    receive() external payable {
        // gotcha
    }

    function balanceOfETH() public view returns (uint256) {
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

        address payable[] memory peeps = new address payable[](3);
        peeps[0] = payable(address(alice));
        peeps[1] = payable(address(bob));
        peeps[2] = payable(address(carol));

        uint256[] memory bps = new uint256[](3);
        bps[0] = 5000;
        bps[1] = 2500;
        bps[2] = 2500;

        split  = new HDSplit(peeps, bps);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance, 100 ether);

        // magic up some token and send to split
    }

    function testPushETH() public {
        assertEq(address(alice).balance, 0);
        assertEq(address(bob).balance,   0);
        assertEq(address(carol).balance, 0);
        assertEq(address(split).balance, 100 ether);

        split.push();

        assertEq(address(alice).balance, 50 ether);
        assertEq(address(bob).balance,   25 ether);
        assertEq(address(carol).balance, 25 ether);
        assertEq(address(split).balance, 0);
    }

    function testPushToken() public {
        assertEq(gold.balanceOf(address(alice)), 0);
        assertEq(gold.balanceOf(address(bob)),   0);
        assertEq(gold.balanceOf(address(carol)), 0);
        assertEq(gold.balanceOf(address(split)), 100 ether);

        split.push(address(gold));

        assertEq(gold.balanceOf(address(alice)), 50 ether);
        assertEq(gold.balanceOf(address(bob)),   25 ether);
        assertEq(gold.balanceOf(address(carol)), 25 ether);
        assertEq(gold.balanceOf(address(split)), 0);
    }
}