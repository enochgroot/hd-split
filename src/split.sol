// SPDX-License-Identifier: GPL-3.0-or-later

/// split.sol -- splits funds sent to this contract

// Copyright (C) 2020 HDSplit

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

contract HDSplit {

    address payable[] public addrs;
    uint256[] public bps;

    // events
    event Push();
    event Sent(address guy, address gem, uint256 amt);

    constructor(address payable[] memory _addrs, uint256[] memory _bps) {
        require(_addrs.length == _bps.length, "HDSplit/length-must-match");

        uint256 _total;

        for (uint256 i = 0; i < _addrs.length; i++) {
            _total = _bps[i];
            addrs.push(_addrs[i]);
            bps.push(_bps[i]);
        }

        require(_total == 10000, "HDSplit/basis-points-must-total-10000");
    }

    function push() external {
        push(address(0));
    }

    function push(address _token) public {
        address _addr;
        uint256 _amt;

        if (_token == address(0)) {
            for (uint256 i = 0; i < addrs.length; i++) {
                _addr = addrs[i]; 
                _amt  = address(this).balance * bps[i];
                emit Sent(_addr, _token, _amt);
                addrs[i].send(_amt);
            }
        } else {
            for (uint256 i = 0; i < addrs.length; i++) {
                _addr = addrs[i]; 
                _amt  = IERC20(_token).balanceOf(address(this)) * bps[i];
                emit Sent(_addr, _token, _amt);
                IERC20(_token).transfer(_addr, _amt);
            }
        }

        emit Push();
    }
}
