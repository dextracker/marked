// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MarkToken is ERC20, Ownable {
    mapping (address => bool) private _marks;
    mapping (address => uint256) private _lastHealed;
    mapping (address => uint256) private _lastTransfer;

    uint256 public _healingPeriod = 10; // Start with a healing period of 10 seconds
    uint256 public _taxAmount;
    address public _taxCollector;

    constructor() ERC20("MarkToken", "MKT") {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) 
    internal 
    override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // Minting new tokens
            _marks[to] = true;
            _lastHealed[to] = block.timestamp;  // Set healing start time
            _lastTransfer[to] = block.timestamp; // Record transfer time
        } else if (to == address(0)) { // Burning tokens
            _marks[from] = false;
        } else { // Regular transfer
            _marks[from] = false;
            _marks[to] = true;
            _lastHealed[to] = block.timestamp;  // Set healing start time
            _lastTransfer[from] = block.timestamp; // Record transfer time for sender
            _lastTransfer[to] = block.timestamp; // Record transfer time for recipient
            _healingPeriod += 1; // Increase healing period by 1 second
        }
    }

    function isMarked(address account) public view returns (bool) {
        if (_marks[account] && (block.timestamp - _lastHealed[account] > _healingPeriod)) {
            return false;  // The mark has been healed over time
        } else {
            return _marks[account];
        }
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function getHealingPeriod(address account) public view returns (uint256) {
        if (_lastTransfer[account] > block.timestamp) {
            return 0;
        } else {
            return block.timestamp - _lastTransfer[account];
        }
    }

    function setTaxAmount(uint256 amount) public onlyOwner {
        _taxAmount = amount;
    }

   function setTaxCollector(address collector) public onlyOwner {
        uint32 size;
        assembly {
            size := extcodesize(collector)
        }
        require(size == 0, "Tax collector can't be a contract");
        _taxCollector = collector;
    }


    function transferWithTax(address recipient, uint256 amount) public {
        require(balanceOf(_msgSender()) >= amount + _taxAmount, "Insufficient balance to cover amount and tax.");
        _transfer(_msgSender(), recipient, amount);
        _transfer(_msgSender(), _taxCollector, _taxAmount);
    }

}
