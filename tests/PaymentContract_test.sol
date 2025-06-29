// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/PaymentContract.sol";
import "../contracts/mocks/MockUSDC.sol";

contract PaymentContractTest is PaymentContract {
    MockUSDC usdc;
    address alice;
    address bob;

    uint256 constant ETH_AMOUNT  = 1 ether;
    uint256 constant USDC_AMOUNT = 100 * 10**6;

    constructor() PaymentContract(TestsAccounts.getAccount(0), address(0)) payable {
        // Owner is account-0, USDC address set in beforeAll
    }

    function beforeAll() public {
        alice = TestsAccounts.getAccount(1);
        bob   = TestsAccounts.getAccount(2);

        usdc = new MockUSDC();
        // Set the USDC token in the inherited contract
        usdc.mint(owner(), USDC_AMOUNT);
        // Use internal assignment via low-level call targeting our storage
        bytes memory payload = abi.encodeWithSignature("setUSDC(address)", address(usdc));
        address(this).call(payload);
    }

    /// #sender: account-1
    /// #value: 1000000000000000000
    function testNativePayment() public payable {
        payWithNative{value: msg.value}();

        (address u, uint256 a, , bool isUSDC) = allPayments(0);
        Assert.equal(u, alice,      "Wrong payer");
        Assert.equal(a, msg.value,  "Amount mismatch");
        Assert.equal(isUSDC, false, "Should be ETH");
    }

    /// #sender: account-1
    /// #value: 0
    function testFailZeroNative() public payable {
        payWithNative{value: 0}();
    }

    /// #sender: account-1
    function testUSDC_Payment() public {
        usdc.mint(alice, USDC_AMOUNT);
        usdc.approve(address(this), USDC_AMOUNT);
        payWithUSDC(USDC_AMOUNT);

        (address u, uint256 a, , bool isUSDC) = allPayments(1);
        Assert.equal(u, alice,       "Wrong USDC payer");
        Assert.equal(a, USDC_AMOUNT, "USDC amount off");
        Assert.equal(isUSDC, true,   "Should be USDC");
    }

    /// #sender: account-2
    function testFailUSDC_NoApproval() public {
        usdc.mint(bob, USDC_AMOUNT);
        payWithUSDC(USDC_AMOUNT);
    }

    /// #sender: account-1
    function testFailUSDC_ZeroAmount() public {
        payWithUSDC(0);
    }

    function testWithdrawals() public {
        /// #sender: account-1
        /// #value: 500000000000000000
        payWithNative{value: 0.5 ether}();

        usdc.mint(alice, USDC_AMOUNT);
        usdc.approve(address(this), USDC_AMOUNT);
        payWithUSDC(USDC_AMOUNT);

        uint256 startETH  = owner().balance;
        uint256 startUSDC = usdc.balanceOf(owner());

        /// #sender: account-0
        withdrawNative();
        /// #sender: account-0
        withdrawUSDC();

        Assert.equal(owner().balance - startETH, 0.5 ether,      "ETH withdrawal failed");
        Assert.equal(usdc.balanceOf(owner()) - startUSDC, USDC_AMOUNT, "USDC withdrawal failed");
        Assert.equal(address(this).balance,        0,           "Contract ETH not zero");
        Assert.equal(usdc.balanceOf(address(this)), 0,          "Contract USDC not zero");
    }

    /// #sender: account-1
    function testFailWithdrawETH_ByNonOwner() public {
        withdrawNative();
    }

    /// #sender: account-2
    function testFailWithdrawUSDC_ByNonOwner() public {
        withdrawUSDC();
    }
}
