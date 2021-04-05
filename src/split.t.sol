// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./test/token.sol";

import "./split.sol";

contract User {

    constructor () {
        // do nothing
    }

    receive() external payable {
        // gotcha
    }

    function pushETH(HDSplit _split) public {
        _split.push();
    }

    function pushToken(HDSplit _split, address _token) public {
        _split.push(_token);
    }
}

contract SplitTest is DSTest {
    HDSplit split;

    User alice;
    User bob;
    User carol;
    User mallory;

    DSToken gold;

    function setUp() public {
        alice   = new User();
        bob     = new User();
        carol   = new User();
        mallory = new User();

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
        gold = new DSToken("GOLD");
        gold.mint(100 ether);
        gold.transfer(address(split), 100 ether);
    }

    function testPushETH() public {
        assertEq(address(alice).balance, 0);
        assertEq(address(bob).balance,   0);
        assertEq(address(carol).balance, 0);
        assertEq(address(split).balance, 100 ether);

        alice.pushETH(split);

        assertEq(address(alice).balance, 50 ether);
        assertEq(address(bob).balance,   25 ether);
        assertEq(address(carol).balance, 25 ether);
        assertEq(address(split).balance, 0);
    }

    function testDoublePushETH() public {
        assertEq(address(alice).balance, 0);
        assertEq(address(bob).balance,   0);
        assertEq(address(carol).balance, 0);
        assertEq(address(split).balance, 100 ether);

        alice.pushETH(split);

        assertEq(address(alice).balance, 50 ether);
        assertEq(address(bob).balance,   25 ether);
        assertEq(address(carol).balance, 25 ether);
        assertEq(address(split).balance, 0);

        bob.pushETH(split);

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

        alice.pushToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 50 ether);
        assertEq(gold.balanceOf(address(bob)),   25 ether);
        assertEq(gold.balanceOf(address(carol)), 25 ether);
        assertEq(gold.balanceOf(address(split)), 0);
    }

    function testDoublePushToken() public {
        assertEq(gold.balanceOf(address(alice)), 0);
        assertEq(gold.balanceOf(address(bob)),   0);
        assertEq(gold.balanceOf(address(carol)), 0);
        assertEq(gold.balanceOf(address(split)), 100 ether);

        alice.pushToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 50 ether);
        assertEq(gold.balanceOf(address(bob)),   25 ether);
        assertEq(gold.balanceOf(address(carol)), 25 ether);
        assertEq(gold.balanceOf(address(split)), 0);

        carol.pushToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 50 ether);
        assertEq(gold.balanceOf(address(bob)),   25 ether);
        assertEq(gold.balanceOf(address(carol)), 25 ether);
        assertEq(gold.balanceOf(address(split)), 0);
    }

    function testBobPushETH() public {
        assertEq(address(alice).balance, 0);
        assertEq(address(bob).balance,   0);
        assertEq(address(carol).balance, 0);
        assertEq(address(split).balance, 100 ether);

        bob.pushETH(split);

        assertEq(address(alice).balance, 50 ether);
        assertEq(address(bob).balance,   25 ether);
        assertEq(address(carol).balance, 25 ether);
        assertEq(address(split).balance, 0);
    }

    function testBobPushToken() public {
        assertEq(gold.balanceOf(address(alice)), 0);
        assertEq(gold.balanceOf(address(bob)),   0);
        assertEq(gold.balanceOf(address(carol)), 0);
        assertEq(gold.balanceOf(address(split)), 100 ether);

        bob.pushToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 50 ether);
        assertEq(gold.balanceOf(address(bob)),   25 ether);
        assertEq(gold.balanceOf(address(carol)), 25 ether);
        assertEq(gold.balanceOf(address(split)), 0);
    }

    function testFailThirdPartyPushETH() public {
        mallory.pushToken(split, address(gold));
    }

    function testFailThirdPartyPushToken() public {
        mallory.pushToken(split, address(gold));
    }

}
