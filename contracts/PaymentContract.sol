// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.1/contracts/token/ERC20/IERC20.sol";

/**
 * @title PaymentContract
 * @dev Receives and logs payments for the Enerlink service.
 */
contract PaymentContract is Ownable {
    // === State Variables ===
    IERC20 public usdcToken;

    struct Payment {
        address user;
        uint256 amount;
        uint256 timestamp;
        bool isUSDC;
    }

    mapping(address => Payment[]) public userPayments;
    Payment[] public allPayments;

    // === Events ===
    event PaymentReceived(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        bool isUSDC
    );

    // === Functions ===
    constructor(address _usdcTokenAddress) Ownable(msg.sender) {
        usdcToken = IERC20(_usdcTokenAddress);
    }

    function payWithNative() public payable {
        require(msg.value > 0, "Payment must be greater than zero");
        _logTransaction(msg.sender, msg.value, false);
    }

    function payWithUSDC(uint256 _amount) public {
        require(_amount > 0, "Payment amount must be greater than zero");

        uint256 currentAllowance = usdcToken.allowance(msg.sender, address(this));
        require(currentAllowance >= _amount, "Check USDC allowance first");
        
        bool success = usdcToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "USDC transfer failed");

        _logTransaction(msg.sender, _amount, true);
    }

    function _logTransaction(address _user, uint256 _amount, bool _isUSDC) private {
        Payment memory newPayment = Payment({
            user: _user,
            amount: _amount,
            timestamp: block.timestamp,
            isUSDC: _isUSDC
        });

        userPayments[_user].push(newPayment);
        allPayments.push(newPayment);

        emit PaymentReceived(_user, _amount, block.timestamp, _isUSDC);
    }

    function withdrawNative() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Native currency withdrawal failed");
    }

    function withdrawUSDC() public onlyOwner {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        usdcToken.transfer(owner(), balance);
    }
}