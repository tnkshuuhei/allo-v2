// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Allo} from "./Allo.sol";
import {Registry} from "./Registry.sol";

/// @title Aqueduct
/// @author 0xZakk (zakk@gitcoin.co)
/// @notice A timelock-style, treasury contract for holding funds until a certain threshold is met and/or time period has passed, then releasing them to a pool
/// @dev This contract works with any ERC20 token, but is not written to work with more than one token or with native Eth. This contract assumes a trusted owner, likely a governance system like Governor Bravo. This contract is a work in progress and is not yet audited. Use at your own risk.
contract Aqueduct {

    struct Round {
        uint256 timestamp;
        uint256 amount;
        address allocation strategy;
    }

    /// ==========================
    /// === Storage Variables ====
    /// ==========================

    /// @notice Location of Allo core
    Allo public allo;

    /// @notice Location of the Allo Registry
    Registry public registry;

    /// @notice The token held by this aqueduct and distributed through Allo
    ERC20 public token;

    /// @notice The identity anchor in the registry
    address public identityId;

    /// @notice Metadata for pools created by this aqueduct
    Metadata public metadata;

    /// @notice List of pool IDs
    uint256[] public poolIds;

    /// @notice Mapping of rounds.
    mapping(uint256 => bool) public pools;

    /// @notice The amount of funds that need to be deposited before the aqueduct will create another pool
    uint256 public minimumTokenThreshold;

    /// @notice The minimum amount of time that needs to elapse between pools being created
    uint256 public minimumElapsedTime;

    /// @notice The default allocation strategy to use for pools created by the aqueduct
    address public allocationStrategy;

    /// @notice Data to pass to the initialize function of the allocation strategy when it's created
    bytes public strategyData;

    /// ==========================
    /// === Errors ===============
    /// ==========================

    /// ==========================
    /// === Events ===============
    /// ==========================

    /// ==========================
    /// === Constructor ==========
    /// ==========================

    constructor(
        ERC20 _token,
        Metadata _metadata,
        uint256 _threshold,
        uint256 _timePeriod,
        address _allocationStrategy,
        bytes _strategyData,
    ) {
        // set variables
        setToken(_token);
        setMetadata(_metadata);
        setThreshold(_threshold);
        setTimePeriod(_timePeriod);
        setAllocationStrategy(_allocationStrategy);
        setStrategyData(_strategyData);

        // create identity for the aqueduct in the registry
        (_nonce, _name, _metadata) = abi.decode(_identity, (uint256, string, Metadata));
        identityId = registry.createIdentity(
            _nonce,
            _name,
            _metadata,
            address(this),   // The pool owner
            address[]        // Pool managers
        );
    }

    /// ==========================
    /// === Methods ==============
    /// ==========================

    /// @notice Create a new pool in Allo and fund it with the tokens held by the aqueduct
    function createAndFundPool(

    ) external {
        // create a new pool in Allo (attached to the aqueduct's identity)
        uint256 poolId = allo.createPool(
            identityId,
            allocationStrategy,
            strategyData,
            address(token),
            token.balanceOf(address(this)),
            metadata,
            address[]
        );
        poolIds.push(poolId);

        // transfer funds to the pool using fundPool
        allo.fundPool(
            poolId,
            token.balanceOf(address(this)),
            address(token)
        );
    }

    /// @notice Set the token address
    /// @param _token Address of the token to be stored and distributed
    function setToken(address _token) public onlyOwner {
        token = ERC20(_token);
        emit SetToken(_token);
    }

    /// @notice Set Metadata for Pools created by the Aqueduct
    /// @param _metadata Pointer to offchain metadata
    function setMetadata(Metadata _metadata) public onlyOwner {
        metadata = _metadata;
        emit SetMetadata(_metadata);
    }

    /// @notice Set the threshold that must be raised before a new pool can be created
    /// @param _threshold The number of tokens that must be raised
    function setThreshold(uint256 _threshold) public onlyOwner {
        minimumTokenThreshold = _threshold;
        emit SetThreshold(_threshold);
    }

    /// @notice Set minimum time that must elapse between rounds
    /// @param _elapsedTime Amount of time that must pass between rounds
    function setTimePeriod(uint256 _elapsedTime) public onlyOwner {
        minimumElapsedTime = _elapsedTime;
        emit SetMinimumElapsedTime(_elapsedTime);
    }

    /// @notice Set the default allocation strategy to use for pools created
    //by the Aqueduct
    /// @param _allocationStrategy Address of the allocation strategy
    /// @dev The createPool method of Allo will clone this contract
    function setAllocationStrategy(address _allocationStrategy) public
    onlyOwner {
        allocationStrategy = _allocationStrategy;
        emit SetAllocationStrategy(_allocationStrategy);
    }

    /// @notice Set the data to pass to the allocation strategy's initalize method
    /// @param _initializationData Bytes encoded data to initialize the allocation strategy
    function setInitialData(bytes memory _initData) public onlyOwner {
        strategyData = _initData;
        emit SetStrategyData(strategyData);
    }


    /// ==========================
    /// === Internal Methods =====
    /// ==========================

    receive() external payable {
        // NOTE: receive ETH
    }

    /// @notice
    function createPool(
        address _identity,
        address _allocationStrategy,
        address _distributionStrategy,
        bytes memory _metadata
    ) external payable returns (uint256) {
        // NOTE: create pool
    }
}
