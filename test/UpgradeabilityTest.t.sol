
/// @title Universal Upgradeability test contract
/// @notice Unit tests for upgradeability of a contract
/// @author Matin Rezaii (@MatinR1) & Behrouz Torabi (@BehrouzT)
/// @dev This test contract is built using Foundry framework

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "forge-std/Test.sol";
import "../src/Upgradeable.sol";

/**
    * @dev This contract inherits the Forge's built-in Test contract.
    * @notice ERC1967 minimal proxy is just used to demonstrate the condition
    *         bypassing in the UUPS contract
    */
contract UpgradeabilityTest is Test {

    using ClonesUpgradeable for address;

    Implementation public impl;
    ImplDeployerProxy public proxy;
    address private owner;
    address private nonAuthorized;
    bytes public data;

    bytes32 internal constant IMPL_SLOT = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);

    function setUp() external {

        owner = vm.addr(1);
        nonAuthorized = address(20);

        data = abi.encodeWithSignature("initialize(address)", owner);

        impl = new Implementation();
        proxy = new ImplDeployerProxy(address(impl), data);
    }

    /**
     * @notice This function checks two conditions:
     *          1 - The implementation contract is not initialized
     *          2 - The proxy contract is already initialized
     */

    function test_initializable() external {

        console.log("The implementation contract is not initialized");
        assertEq(impl.getOwner(), address(0));

        (bool success, ) = address(proxy).call(abi.encodeWithSignature("initialize(address)", owner));
        assertFalse(success);
    }

    /**
     * @notice This function creates an attack scenario to upgrade the contract
     *         to a malicious contract. As the implementation contract is not
     *         initialized at first, we'll try to upgrade the contract to a malicious
     *         contract.
     */

    function test_uninitializedImplAttack() external {

        console.log("Initializing the implementation contract");

        // now the malicious person becomes an authorized pesron for the implementation contract
        // Let's try to change the IMPL_SLOT address of proxy to a new contract
        impl.initialize(nonAuthorized);
        assertEq(impl.getOwner(), nonAuthorized);

        vm.startPrank(nonAuthorized);

        Implementation impl2 = new Implementation();
        ImplDeployerProxy proxy2 = new ImplDeployerProxy(address(impl), "");

        vm.expectRevert("Function must be called through delegatecall");
        impl.upgradeTo(address(impl2));

        vm.expectRevert("Function must be called through active proxy");
        address(proxy2).delegatecall(abi.encodeWithSignature("upgradeTo(address)", address(impl2)));

        // Let's try to bypass the preceding conditions with minimal proxies

        address implClone = ClonesUpgradeable.clone(address(impl));
        vm.expectRevert("Function must be called through active proxy");
        Implementation(implClone).upgradeTo(address(impl2));

        /*  The first condition is bypassed however the second one is persistent!
            It illustrates that if a contract inherits the UUPSUpgradeable.sol contract
            the upgradeTo() couldn't be performed via malicious attacks as it includes
            two strong conditions.
         */
        vm.stopPrank();
    }
    
    /**
     * @notice This function checks the implementation address inside the IMPL_SLOT
     *         
     */
    function test_proxyImplSlot() external {

        console.log("Ensuring the IMPL_SLOT of proxy holds the implementation address");
        bytes32 proxySlot = vm.load(address(proxy), IMPL_SLOT);
        assertEq(proxySlot, bytes32(uint256(uint160(address(impl)))));
    }

    /**
     * @notice This function tests the upgradeability mechanism of the contracts
     */
    function test_implUpgradeTo() external {

        vm.startPrank(nonAuthorized);

        Implementation impl2 = new Implementation();        

        vm.expectRevert();
        address(proxy).delegatecall(abi.encodeWithSignature("upgradeTo(address)", address(impl2)));

        vm.stopPrank();
        vm.startPrank(owner);

        impl.initialize(owner);
        assertEq(impl.getOwner(), owner);

        // Checking the IMPL_SLOT before upgrading the implementation contract
        bytes32 proxySlotBefore = vm.load(address(proxy), IMPL_SLOT);
        assertEq(proxySlotBefore, bytes32(uint256(uint160(address(impl)))));        

        (bool success, ) = address(proxy).delegatecall(abi.encodeWithSignature("upgradeTo(address)", address(impl2)));
        assertTrue(success);

        bytes32 proxySlotAfter = vm.load(address(proxy), IMPL_SLOT);
        assertEq(proxySlotAfter, bytes32(uint256(uint160(address(impl)))));
        // Upgrade is successful!
    }
}