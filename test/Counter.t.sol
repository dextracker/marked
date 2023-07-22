// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Marked.sol";

contract MarkedTest is Test {
    MarkToken public markToken;
    string public markTokenName = "MarkToken";
    address public dev = address(0x2404fc115dBCb35DCAE5465bD878d155b34017e3);


    function setUp() public {
        vm.prank(dev);
        markToken = new MarkToken();
    }

    function testSetTaxCollector() public {
        vm.prank(dev);
        markToken.setTaxCollector(
            address(dev)
        );
        address taxCollector = markToken._taxCollector();
        assert(taxCollector == dev);
    }

    function testMarktokenERC20Functionality() public {
        vm.startPrank(markToken.owner());
        markToken.mint(address(this), 1e18);
        vm.stopPrank();
        assert(markToken.balanceOf(address(this)) == 1e18);
        markToken.approve(address(this), 1e18);
        markToken.balanceOf(address(this));
        markToken.transferFrom(address(this), address(dev), 1e18);
        vm.expectRevert(markToken.transfer.selector);
        
        vm.warp(block.timestamp + 10 minutes);
        markToken.transfer(address(dev), 1e18);
        

    }


}
