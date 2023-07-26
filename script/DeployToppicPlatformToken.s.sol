// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {ToppicPlatformToken} from "../src/ToppicPlatformToken.sol";

contract DeployToppicPlatformToken is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public deployerKey;

    function setUp() external {}

    function run() external returns (ToppicPlatformToken) {
        if (block.chainid == 31337) {
            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
        } else {
            deployerKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerKey);
        // Deploy the ToppicPlatformToken contract
        ToppicPlatformToken toppicPlatformToken = new ToppicPlatformToken();
        vm.stopBroadcast();

        return (toppicPlatformToken);
    }
}
