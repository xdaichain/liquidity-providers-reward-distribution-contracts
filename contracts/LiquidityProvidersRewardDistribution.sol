pragma solidity 0.6.7;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";

contract LiquidityProvidersRewardDistribution is OwnableUpgradeSafe {
    using Address for address;

    IERC20 public token;
    address public distributor;

    event Distributed(
        uint256 snapshotBlockNumber,
        uint256 numberOfRewards,
        uint256 total,
        uint256 fee
    );

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
        uint256[] calldata _rewards,
        uint256 _fee
    ) external {
        require(distributor == _msgSender(), "caller is not the distributor");
        uint256 numberOfRewards = _rewards.length;
        require(_liquidityProviders.length == numberOfRewards, "different sizes of arrays");
        uint256 total;
        for (uint256 i = 0; i < numberOfRewards; i++) {
            token.transfer(_liquidityProviders[i], _rewards[i]);
            total += _rewards[i];
        }
        token.transfer(distributor, _fee);
        total += _fee;
        emit Distributed(_snapshotBlockNumber, numberOfRewards, total, _fee);
    }

    function getBalanceAndBlockNumber() external view returns (uint256 balance, uint256 blockNumber) {
        return (token.balanceOf(address(this)), block.number);
    }
}
