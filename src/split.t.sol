// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "./split.sol";

contract User {

    constructor () public {
        // do nothing
    }

    receive() external payable {
        // gotcha
    }

    function approve(DSToken _token, HDSplit _split) public {
        _token.approve(address(_split), uint256(-1));
    }

    function tell(HDSplit _split, uint256 _wad) public {
        _split.tell(_wad);
    }

    function takeETH(HDSplit _split) public {
        _split.take();
    }

    function takeToken(HDSplit _split, address _token) public {
        _split.take(_token);
    }
}

contract SplitTest is DSTest {
    HDSplit split;

    User alice;
    User bob;
    User carol;
    User mallory;

    DSToken gold;
    DSToken dai;

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

        // magic up some token and send to split
        dai = new DSToken("DAI");
        dai.mint(4000 ether);
        dai.transfer(address(alice),   1000 ether);
        dai.transfer(address(bob),     1000 ether);
        dai.transfer(address(carol),   1000 ether);
        dai.transfer(address(mallory), 1000 ether);

        split = new HDSplit(address(dai), 50_000 ether, peeps, bps);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance, 100 ether);

        // magic up some token and send to split
        gold = new DSToken("GOLD");
        gold.mint(10000 ether);
        gold.transfer(address(split), 100 ether);

        // set approvals
        alice.approve(dai, split);
        bob.approve(dai, split);
        carol.approve(dai, split);
    }

    function testTakeETH() public {
        assertEq(address(alice).balance,    0 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)),   0 ether);

        alice.takeETH(split);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        bob.takeETH(split);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,     25 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   25 ether);
        assertEq(split.total(address(0)),  25 ether);

        carol.takeETH(split);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,     25 ether);
        assertEq(address(carol).balance,   25 ether);
        assertEq(address(split).balance,    0 ether);
        assertEq(split.total(address(0)),   0 ether);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)),   0 ether);

        alice.takeETH(split);

        assertEq(address(alice).balance,  100 ether);
        assertEq(address(bob).balance,     25 ether); // still owed 25
        assertEq(address(carol).balance,   25 ether); // still owed 25
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance,  150 ether);
        assertEq(split.total(address(0)),  50 ether);

        bob.takeETH(split);

        assertEq(address(alice).balance,  100 ether); // still owed 50
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   25 ether); // still owed 50
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)), 100 ether);

        carol.takeETH(split);

        assertEq(address(alice).balance,  100 ether); // still owed 50
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   75 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        alice.takeETH(split);

        assertEq(address(alice).balance,  150 ether);
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   75 ether);
        assertEq(address(split).balance,    0 ether);
        assertEq(split.total(address(0)),   0 ether);

    }

    function testDoubleTakeETH() public {
        assertEq(address(alice).balance,    0 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)),   0 ether);

        alice.takeETH(split);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        alice.takeETH(split);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);
    }

    function testTakeToken() public {
        assertEq(gold.balanceOf(address(alice)),   0 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)), 100 ether);
        assertEq(split.total(address(gold)),       0 ether);

        alice.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),  50 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)),  50 ether);
        assertEq(split.total(address(gold)),      50 ether);

        bob.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),  50 ether);
        assertEq(gold.balanceOf(address(bob)),    25 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)),  25 ether);
        assertEq(split.total(address(gold)),      25 ether);

        carol.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),  50 ether);
        assertEq(gold.balanceOf(address(bob)),    25 ether);
        assertEq(gold.balanceOf(address(carol)),  25 ether);
        assertEq(gold.balanceOf(address(split)),   0 ether);
        assertEq(split.total(address(gold)),       0 ether);

        // magic up some token and send to split
        gold.transfer(address(split), 100 ether);
        assertEq(gold.balanceOf(address(split)), 100 ether);
        assertEq(split.total(address(gold)),       0 ether);

        alice.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 100 ether);
        assertEq(gold.balanceOf(address(bob)),    25 ether); // still owed 25
        assertEq(gold.balanceOf(address(carol)),  25 ether); // still owed 25
        assertEq(gold.balanceOf(address(split)),  50 ether);
        assertEq(split.total(address(gold)),      50 ether);

        // magic up some token and send to split
        gold.transfer(address(split), 100 ether);
        assertEq(gold.balanceOf(address(split)), 150 ether);
        assertEq(split.total(address(gold)),      50 ether);

        bob.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 100 ether); // still owed 50
        assertEq(gold.balanceOf(address(bob)),    75 ether);
        assertEq(gold.balanceOf(address(carol)),  25 ether); // still owed 50
        assertEq(gold.balanceOf(address(split)), 100 ether);
        assertEq(split.total(address(gold)),     100 ether);

        carol.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 100 ether); // still owed 50
        assertEq(gold.balanceOf(address(bob)),    75 ether);
        assertEq(gold.balanceOf(address(carol)),  75 ether);
        assertEq(gold.balanceOf(address(split)),  50 ether);
        assertEq(split.total(address(gold)),      50 ether);

        alice.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)), 150 ether);
        assertEq(gold.balanceOf(address(bob)),    75 ether);
        assertEq(gold.balanceOf(address(carol)),  75 ether);
        assertEq(gold.balanceOf(address(split)),   0 ether);
        assertEq(split.total(address(gold)),       0 ether);
    }

    function testDoubleTakeToken() public {
        assertEq(gold.balanceOf(address(alice)),   0 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)), 100 ether);
        assertEq(split.total(address(gold)),       0 ether);

        alice.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),  50 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)),  50 ether);
        assertEq(split.total(address(gold)),      50 ether);

        alice.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),  50 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)),  50 ether);
        assertEq(split.total(address(gold)),      50 ether);
    }

    function testBobTakeETH() public {
        assertEq(address(alice).balance,    0 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)),   0 ether);

        bob.takeETH(split);

        assertEq(address(alice).balance,    0 ether);
        assertEq(address(bob).balance,     25 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   75 ether);
        assertEq(split.total(address(0)),  75 ether);
    }

    function testBobTakeToken() public {
        assertEq(gold.balanceOf(address(alice)),   0 ether);
        assertEq(gold.balanceOf(address(bob)),     0 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)), 100 ether);
        assertEq(split.total(address(gold)),       0 ether);

        bob.takeToken(split, address(gold));

        assertEq(gold.balanceOf(address(alice)),   0 ether);
        assertEq(gold.balanceOf(address(bob)),    25 ether);
        assertEq(gold.balanceOf(address(carol)),   0 ether);
        assertEq(gold.balanceOf(address(split)),  75 ether);
        assertEq(split.total(address(gold)),      75 ether);
    }

    function testTellTakeETH() public {
        assertEq(dai.balanceOf(address(alice)), 1000 ether);
        assertEq(dai.balanceOf(address(bob)),   1000 ether);
        assertEq(dai.balanceOf(address(carol)), 1000 ether);

        alice.tell(split, 100 ether);
        assertEq(split.debt(), 50 ether);

        alice.takeETH(split);

        // alice has to pay herself, but balances don't change
        assertEq(dai.balanceOf(address(alice)), 1000 ether); // owes alice  0
        assertEq(dai.balanceOf(address(bob)),   1000 ether); // owes alice 25
        assertEq(dai.balanceOf(address(carol)), 1000 ether); // owes alice 25

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,      0 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        bob.takeETH(split);

        // bob had to pay alice 25 DAI
        assertEq(dai.balanceOf(address(alice)), 1025 ether); // owes alice  0
        assertEq(dai.balanceOf(address(bob)),    975 ether); // owes alice  0
        assertEq(dai.balanceOf(address(carol)), 1000 ether); // owes alice 25
        assertEq(split.debt(), 25 ether);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,     25 ether);
        assertEq(address(carol).balance,    0 ether);
        assertEq(address(split).balance,   25 ether);
        assertEq(split.total(address(0)),  25 ether);

        carol.takeETH(split);

        // carol had to pay alice 25 DAI
        assertEq(dai.balanceOf(address(alice)), 1050 ether); // owes alice  0
        assertEq(dai.balanceOf(address(bob)),    975 ether); // owes alice  0
        assertEq(dai.balanceOf(address(carol)),  975 ether); // owes alice  0
        assertEq(split.debt(), 0 ether);

        assertEq(address(alice).balance,   50 ether);
        assertEq(address(bob).balance,     25 ether);
        assertEq(address(carol).balance,   25 ether);
        assertEq(address(split).balance,    0 ether);
        assertEq(split.total(address(0)),   0 ether);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)),   0 ether);

        // bob also has an expense of 100 DAI
        bob.tell(split, 100 ether);
        assertEq(split.debt(), 75 ether);

        alice.takeETH(split);

        assertEq(dai.balanceOf(address(alice)), 1000 ether); // owes bob  0
        assertEq(dai.balanceOf(address(bob)),   1025 ether); // owes bob 25
        assertEq(dai.balanceOf(address(carol)),  975 ether); // owes bob 25
        assertEq(split.debt(), 25 ether);

        assertEq(address(alice).balance,  100 ether);
        assertEq(address(bob).balance,     25 ether); // still owed 25
        assertEq(address(carol).balance,   25 ether); // still owed 25
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        // magic up some ETH and send to split
        payable(address(split)).transfer(100 ether);
        assertEq(address(split).balance,  150 ether);
        assertEq(split.total(address(0)),  50 ether);

        // alice has another expense of 100 DAI
        alice.tell(split, 100 ether);
        assertEq(split.debt(), 75 ether);

        bob.takeETH(split);

        assertEq(dai.balanceOf(address(alice)), 1025 ether); // owes alice 50, bob  0
        assertEq(dai.balanceOf(address(bob)),   1000 ether); // owes alice  0, bob  0
        assertEq(dai.balanceOf(address(carol)),  975 ether); // owes alice 25, bob 25
        assertEq(split.debt(), 50 ether);

        assertEq(address(alice).balance,  100 ether); // still owed 50
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   25 ether); // still owed 50
        assertEq(address(split).balance,  100 ether);
        assertEq(split.total(address(0)), 100 ether);

        carol.takeETH(split);

        assertEq(dai.balanceOf(address(alice)), 1050 ether); // owes alice 50, bob  0
        assertEq(dai.balanceOf(address(bob)),   1025 ether); // owes alice  0, bob  0
        assertEq(dai.balanceOf(address(carol)),  925 ether); // owes alice  0, bob  0
        assertEq(split.debt(), 0 ether);

        assertEq(address(alice).balance,  100 ether); // still owed 50
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   75 ether);
        assertEq(address(split).balance,   50 ether);
        assertEq(split.total(address(0)),  50 ether);

        alice.takeETH(split);

        assertEq(dai.balanceOf(address(alice)), 1050 ether); // owes alice  0, bob  0
        assertEq(dai.balanceOf(address(bob)),   1025 ether); // owes alice  0, bob  0
        assertEq(dai.balanceOf(address(carol)),  925 ether); // owes alice  0, bob  0
        assertEq(split.debt(), 0 ether);

        assertEq(address(alice).balance,  150 ether);
        assertEq(address(bob).balance,     75 ether);
        assertEq(address(carol).balance,   75 ether);
        assertEq(address(split).balance,    0 ether);
        assertEq(split.total(address(0)),   0 ether);

    }

    function testFailThirdPartyTakeETH() public {
        mallory.takeToken(split, address(gold));
    }

    function testFailThirdPartyTakeToken() public {
        mallory.takeToken(split, address(gold));
    }

    function testFailThirdPartyTell() public {
        mallory.tell(split, 10_000 ether);
    }

    function testTellLimit() public {
        alice.tell(split, 10_000 ether);
        assertEq(split.debt(), 5_000 ether);
        bob.tell(split, 10_000 ether);
        assertEq(split.debt(), 12_500 ether);
        carol.tell(split, 10_000 ether);
        assertEq(split.debt(), 20_000 ether);
        alice.tell(split, 10_000 ether);
        assertEq(split.debt(), 25_000 ether);
        bob.tell(split, 10_000 ether);
        assertEq(split.debt(), 32_500 ether);
        carol.tell(split, 10_000 ether);
        assertEq(split.debt(), 40_000 ether);
        alice.tell(split, 10_000 ether);
        assertEq(split.debt(), 45_000 ether);
    }

    function testFailTellLimit() public {
        alice.tell(split, 10_000 ether);
        bob.tell(split, 10_000 ether);
        carol.tell(split, 10_000 ether);
        alice.tell(split, 10_000 ether);
        bob.tell(split, 10_000 ether);
        carol.tell(split, 10_000 ether);
        alice.tell(split, 10_000 ether);
        assertEq(split.debt(), 45_000 ether);
        // fail
        bob.tell(split, 10_000 ether);
    }

}