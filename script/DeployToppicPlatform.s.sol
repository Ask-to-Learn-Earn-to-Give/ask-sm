// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {ToppicPlatformToken} from "../src/ToppicPlatformToken.sol";
import {ToppicPlatform} from "../src/ToppicPlatform.sol";

contract DeploytopicPlatform is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;
    ToppicPlatformToken public toppicPlatformToken;
    address public contractToken;

    constructor() {
        toppicPlatformToken = new ToppicPlatformToken();
        contractToken = toppicPlatformToken.getContractAddress();
    }

    function setUp() external {}

    function run() external returns (ToppicPlatform) {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerKey);
        // Deploy the topicPlatform contract
        ToppicPlatform topicPlatform = new ToppicPlatform({
            _tokenContract: contractToken
        });
        vm.stopBroadcast();

        return (topicPlatform);
    }
}
