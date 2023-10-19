// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {ITreasury} from "./ITreasury.sol";

contract Counter is BaseHook {
    using PoolIdLibrary for PoolKey;
    ITreasury public treasury;


    constructor(IPoolManager _poolManager, address _treasury) BaseHook(_poolManager) {
        treasury = ITreasury(_treasury);
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4) {
        uint256 protocolReserves = poolManager.reservesOf(treasury.getProtocolToken());
        uint256 usdcReserves = poolManager.reservesOf(treasury.getUsdcToken());
        uint256 price = protocolReserves / usdcReserves;
        uint256 amountToBuy = (usdcReserves - protocolReserves) > price ? price : (usdcReserves - protocolReserves);
        if (price < 1) {
            IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
                zeroForOne: false,
                amountSpecified: int256(amountToBuy),
                sqrtPriceLimitX96: uint160(0)
            });
            treasury.swapTokens(params, block.timestamp + 30);
        }
        return Counter.afterSwap.selector;
    }

}
