// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structure/Pack.sol";

interface IOpenPack {

    function openPack(Pack memory packToOpen) external;
}
