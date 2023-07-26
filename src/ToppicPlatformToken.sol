// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ToppicPlatformToken is ERC20 {
    constructor() ERC20("Ask Token", "ASK") {
        uint256 totalSupply = 1_000_000_000 * 10 ** decimals();
        _mint(msg.sender, totalSupply);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(to != address(0), "Cannot transfer to the zero address");
        require(amount <= balanceOf(msg.sender), "Not enough balance");

        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(from != address(0), "Cannot transfer from the zero address");
        require(to != address(0), "Cannot transfer to the zero address");
        require(amount <= balanceOf(from), "Not enough balance");
        require(amount <= allowance(from, msg.sender), "Not enough allowance");

        _transfer(from, to, amount);
        _approve(from, msg.sender, allowance(from, msg.sender) - amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        require(spender != address(0), "Cannot approve the zero address");

        _approve(msg.sender, spender, amount);
        return true;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }
}
