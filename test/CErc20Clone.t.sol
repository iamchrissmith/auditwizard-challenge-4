
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/CErc20Clone.sol";

contract CErc20CloneTest is Test {
    Token token;
    CErc20Clone cErc20Clone;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new Token();
        cErc20Clone = new CErc20Clone(address(token));

        // Allocate tokens to Alice and Bob
        token.transfer(alice, 1000 ether);
        token.transfer(bob, 1000 ether);

        // Approve CErc20Clone contract to spend Alice's and Bob's tokens
        vm.prank(alice);
        token.approve(address(cErc20Clone), 1000 ether);

        vm.prank(bob);
        token.approve(address(cErc20Clone), 1000 ether);
    }

    function testMintAndRedeemWithExternalTransfer() public {
        // Alice mints 100 tokens
        vm.prank(alice);
        cErc20Clone.mint(alice, 100 ether);

        assertEq(cErc20Clone.accountTokens(alice), 100 ether);
        assertEq(cErc20Clone.totalSupply(), 100 ether);
        assertEq(token.balanceOf(address(cErc20Clone)), 100 ether);

        // Bob transfers 50 tokens to the contract
        vm.prank(bob);
        token.transfer(address(cErc20Clone), 50 ether);

        // Alice redeems her tokens
        vm.prank(alice);
        cErc20Clone.redeem(alice);

        // Check Alice's final balance
        uint256 aliceFinalBalance = token.balanceOf(alice);
        console.log("Alice's final balance:", aliceFinalBalance);

        // Assert that Alice's redeemed amount is less than 100 ether due to Bob's transfer
        assertLt(aliceFinalBalance, 100 ether);
    }
}
