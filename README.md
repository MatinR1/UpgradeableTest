# UpgradeableTest
... And Vitalik said, “Let there be Proxies!”

## Overview
This repo is intended to test the upgradeability mechanism for UUPS-type proxies using the Foundry toolkit.

## Rationale
The aim of this project is for testing the functionality of the UUPS-type proxies. The UUPS upgradeability scheme is enabled via [OpenZeppelin's 
upgradeable libraries](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tree/master/contracts/proxy). The deployment procedure is
considered to be using Remix online IDE **Deploy with Proxy** which uses the OpenZeppelin's built-in upgrading plugin.
Testing is performed using Foundry's forge tool with focusing on four main vulnerabilities of these types of proxies which will be discussed in the preceding.


## Proxy
In Web3 the proxy pattern is one of the most popular patterns for upgrading the contracts. As the notion of upgradeability is in contrast with the
concept of the immutability of the blockchains, however, the necessity for doing some vital changes to the contract in the case of a bug or other things
exists and developers need to upgrade their contracts. The mechanism for upgrading the contracts is made possible with the low-level ```delegatecall```
method. With this method, the storage is with the proxy contract while the logic is from the target contract. Fig.1 illustrates the mechanism of
```delegatecall```:

![Figure 1](https://github.com/MatinR1/UpgradeableTest/blob/master/Delegatecall.png?raw=true)

It's worth mentioning that proxies are not meant to be created dedicatedly for upgrading purposes, and they have other use cases though.
With an understanding of the proxy contracts and their working mechanism, it's nice to look at some existing types of upgradeable proxies:

* Transparent Proxy (TPP)
* Universal Upgradeable Proxy (UUPS)
* Beacon Proxy
* Diamond Proxy

For Further study please refer to [this link](https://proxies.yacademy.dev/pages/proxies-list/).
The main vulnerabilities from which these kinds of proxies suffer [are](https://proxies.yacademy.dev/pages/security-guide/): 

* Uninitialized Proxy
* Storage Collision
* Function Clashing
* Unsafe Delegatecall Issues

## Methodology
First, we write a simple implementation contract that inherits OpenZeppelin's UUPS contract. This contract is just used for upgrading purposes
and checking its functionality is out of this work's scope. <br >
Starting inheriting from Forge's test contract, we investigate both the initialization of the implementation contract as well as the proxy contract.
Next, we assess the possible attack vectors for uninitialized implementation which inherits the UUPS contract. <br>
Checking the address of the implementation contract stored in the EIP-1967 slots of the proxy contract, and testing the upgrading task itself
are also performed.

## Conclusion

Foundry toolkit is able to perform upgrading tests using its powerful tool Forge. The uninitialized implementation problem is also prevented by 
inheriting the UUPSUpgradeable.sol contract. The proxy contract is initialized when deploying thus we cannot have an uninitialized proxy problem.
The implementation slot of the proxy (EIP-1967) is successfully changed and overwritten during an upgrading procedure.

