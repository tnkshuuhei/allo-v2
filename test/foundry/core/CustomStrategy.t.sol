// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Interfaces
import {IAllo} from "../../../contracts/core/interfaces/IAllo.sol";
import {IStrategy} from "../../../contracts/core/interfaces/IStrategy.sol";
// Core contracts
import {Allo} from "../../../contracts/core/Allo.sol";
import {Registry} from "../../../contracts/core/Registry.sol";
// Internal Libraries
import {Errors} from "../../../contracts/core/libraries/Errors.sol";
import {Metadata} from "../../../contracts/core/libraries/Metadata.sol";
import {Native} from "../../../contracts/core/libraries/Native.sol";
// Test libraries
import {AlloSetup} from "../shared/AlloSetup.sol";
import {RegistrySetupFull} from "../shared/RegistrySetup.sol";
import {MockERC20} from "../../utils/MockERC20.sol";
import {GasHelpers} from "../../utils/GasHelpers.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";
import {ISignatureTransfer} from "permit2/ISignatureTransfer.sol";
import {PermitSignature} from "lib/permit2/test/utils/PermitSignature.sol";
import {Permit2} from "../../utils/Permit2Mock.sol";
import {DonationVotingMerkleDistributionDirectTransferStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-distribution-direct-transfer/DonationVotingMerkleDistributionDirectTransferStrategy.sol";
import {DonationVotingMerkleDistributionBaseStrategy} from
    "../../../contracts/strategies/donation-voting-merkle-base/DonationVotingMerkleDistributionBaseStrategy.sol";

contract CustomStrategyTest is Test, AlloSetup, RegistrySetupFull, Native, Errors, GasHelpers {
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );
    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);
    event PoolFunded(uint256 indexed poolId, uint256 amount, uint256 fee);
    event BaseFeePaid(uint256 indexed poolId, uint256 amount);
    event TreasuryUpdated(address treasury);
    event PercentFeeUpdated(uint256 percentFee);
    event BaseFeeUpdated(uint256 baseFee);
    event RegistryUpdated(address registry);
    event StrategyApproved(address strategy);
    event StrategyRemoved(address strategy);

    error AlreadyInitialized();

    ISignatureTransfer public permit2;
    address public strategy;
    MockERC20 public token;

    uint256 mintAmount = 1000000 * 10 ** 18;

    Metadata public metadata = Metadata({protocol: 1, pointer: "strategy pointer"});
    string public name;
    uint256 public nonce;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        permit2 = ISignatureTransfer(address(new Permit2()));

        __RegistrySetupFull();
        __AlloSetup(address(_registry_));
        token = new MockERC20();

        vm.startPrank(alice);
        token.mint(alice, 10000);
        token.mint(bob, 10000);
        token.mint(carol, 10000);
        vm.stopPrank();
    }

    function testDeployStrategy() public {
        address[] memory members = new address[](3);
        members[0] = alice;
        members[1] = bob;
        members[2] = carol;

        // Metadata memory metadata = Metadata({protocol: 1, pointer: "ipfs://Qefdadhlk"});

        vm.startPrank(alice);

        address[] memory allowedTokens = new address[](2);
        allowedTokens[0] = address(token);
        allowedTokens[1] = NATIVE;
        uint64 registrationStartTime = 0;
        uint64 registrationEndTime = 1000;
        uint64 allocationStartTime = 1000;
        uint64 allocationEndTime = 2000;

        DonationVotingMerkleDistributionBaseStrategy.InitializeData memory data =
        DonationVotingMerkleDistributionBaseStrategy.InitializeData({
            useRegistryAnchor: true,
            metadataRequired: true,
            registrationStartTime: registrationStartTime,
            registrationEndTime: registrationEndTime,
            allocationStartTime: allocationStartTime,
            allocationEndTime: allocationEndTime,
            allowedTokens: allowedTokens
        });
        bytes memory initStrategyData = abi.encode(data);
        bytes32 profileId = _registry_.createProfile(0, "Test Profile", metadata, alice, members);
        address customStrategy = __deployStrategy();

        token.approve(address(allo()), 1000);
        uint256 poolId = allo().createPoolWithCustomStrategy(
            profileId, customStrategy, initStrategyData, address(token), 1000, metadata, members
        );
        assertEq(poolId, 1);

        vm.stopPrank();
    }

    function __deployStrategy() internal returns (address) {
        strategy = address(
            new DonationVotingMerkleDistributionDirectTransferStrategy(address(allo()), "DonationVotingTest", permit2)
        );
        return strategy;
    }
}
