// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IFantomMarketplace {
    function minters(
        address, // NFT address
        uint256 // tokenId
    ) external returns (address);
}
