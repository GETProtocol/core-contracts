// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITestERC20Decimals } from "./interfaces/ITestERC20Decimals.sol";

// prettier-ignore
contract TestERC20Decimals is ITestERC20Decimals, Context, ERC20 {
    uint8 private _decimals;

    /**
     * @dev Initializes ERC20 token
     */
    constructor(string memory name, string memory symbol, uint256 decimal) ERC20(name, symbol) {
        _decimals = uint8(decimal);
    }

    /**
     * @dev Creates `amount` new tokens for `to`. Public for any test to call.
     *
     * See {ERC20-_mint}.
     */
    function mint(address to, uint256 amount) public virtual override {
        // Not expected to be true protection, but we don't ever mint more than 3.4M tokens at a given time within test
        // and pre-prod environments. Makes it economically unviable to mint the max uint256 to break the environment.
        // 100M (times 1000 because of the migration of GET to OPN) chosen to add a bit of breathing room.
        require(amount <= 100_000_000_000 * 10 ** _decimals, "TestERC20Decimals: above maximum allowed mint");
        _mint(to, amount);
    }

    function burn(uint256 amount) public  {
        _burn(_msgSender(), amount);
    }

    function decimals() public view virtual override(ERC20, ITestERC20Decimals) returns (uint8) {
        return _decimals;
    }
}
