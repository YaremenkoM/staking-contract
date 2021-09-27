// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Stakeable.sol";


contract MashToken is ERC20, Ownable, Stakeable {
    constructor(uint256 initialSupply) ERC20("MashToken", "MASH") {
        _mint(msg.sender, initialSupply);
    }


    function stake(uint256 _amount) public{
      require(_amount <= balanceOf(msg.sender), "Cannot stake more than you owns");
      require(_amount > 0, "Need to stake smth, cant stake nothing");

      _stake(_amount);
      _burn(msg.sender, _amount);
    }


    function claim() external {
      _claim(0);
    }

    function claimAndWithdraw(uint256 amount) external{
       require(amount > 0, "If it needed nothing to withdraw, call claim() function");
       _claim(amount);
    }

    function withdraw() external{
        uint256 toWithdraw = _withdraw();
        _mint(msg.sender, toWithdraw);
    }

    function stakingSummary() external view returns(uint256){
        return _stakingSummary();
    }
}