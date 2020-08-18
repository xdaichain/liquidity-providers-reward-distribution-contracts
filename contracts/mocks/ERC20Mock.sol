pragma solidity 0.6.7;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20UpgradeSafe {
    function initialize() external initializer {
        __ERC20_init('Stake', 'STAKE');
    }

    function mint(address _account, uint256 _value) external {
        _mint(_account, _value);
    }
}
