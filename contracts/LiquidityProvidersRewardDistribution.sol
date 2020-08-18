pragma solidity 0.6.7;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

contract LiquidityProvidersRewardDistribution is OwnableUpgradeSafe {
    using Address for address;

    IERC20 public token;
    address public distributor;

    event Distributed(uint256 snapshotBlockNumber);

    function initialize(
        address _owner,
        address _distributor,
        address _tokenAddress
    ) external initializer {
        require(_owner != address(0), "zero address");
        require(_tokenAddress.isContract(), "not a contract address");
        __Ownable_init();
        token = IERC20(_tokenAddress);
        setDistributorAddress(_distributor);
        OwnableUpgradeSafe.transferOwnership(_owner);
    }

    function setDistributorAddress(address _distributor) public onlyOwner {
        require(_distributor != address(0), "zero address");
        distributor = _distributor;
    }

    function distribute(
        uint256 _snapshotBlockNumber,
        address[] calldata _liquidityProviders,
        uint256[] calldata _rewards
    ) external {
        require(distributor == _msgSender(), "caller is not the distributor");
        for (uint256 i = 0; i < _liquidityProviders.length; i++) {
            token.transfer(_liquidityProviders[i], _rewards[i]);
        }
        emit Distributed(_snapshotBlockNumber);
    }
}
