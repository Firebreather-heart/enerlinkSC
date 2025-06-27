// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/PaymentContract.sol";
import "../contracts/mocks/MockUSDC.sol";

contract PaymentContractTest {
    PaymentContract paymentContract;
    MockUSDC mockUSDC;
    address owner;
    address user1;
    uint256 constant paymentAmountUSDC = 100 * 10**18;

    function beforeAll() public {
        owner = TestsAccounts.getAccount(0);
        user1 = TestsAccounts.getAccount(1);

        mockUSDC = new MockUSDC();
        paymentContract = new PaymentContract(address(mockUSDC));

        mockUSDC.mint(user1, paymentAmountUSDC * 2);
    }

    function check_initial_owner() public {
        Assert.equal(paymentContract.owner(), owner, "Owner should be account 0");
    }

    function it_should_accept_native_payment() public {
        uint beforeBalance = address(paymentContract).balance;
        Assert.ok(
            address(paymentContract).call{value: 1 ether}(""),
            "Native payment transaction failed"
        );
        uint afterBalance = address(paymentContract).balance;
        Assert.equal(afterBalance, beforeBalance + 1 ether, "Contract balance should increase by 1 ether");
    }

    function it_should_accept_USDC_payment() public {
        // As user1, approve the contract to spend USDC
        vm.prank(user1);
        mockUSDC.approve(address(paymentContract), paymentAmountUSDC);

        // As user1, make the payment
        vm.prank(user1);
        paymentContract.payWithUSDC(paymentAmountUSDC);

        uint256 contractBalance = mockUSDC.balanceOf(address(paymentContract));
        Assert.equal(contractBalance, paymentAmountUSDC, "Contract USDC balance is incorrect");
    }

    function it_should_fail_if_non_owner_withdraws_native() public {
        // Set calling account to user1 for this test
        vm.prank(user1);
        try paymentContract.withdrawNative() {
            Assert.ok(false, "Withdrawal should have failed for non-owner");
        } catch Error(string memory reason) {
            Assert.equal(reason, "Ownable: caller is not the owner", "Wrong revert reason");
        }
    }
}