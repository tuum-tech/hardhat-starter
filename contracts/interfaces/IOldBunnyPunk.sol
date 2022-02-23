// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IOldBunnyPunk {
    /// ERC721 function
    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external returns (bool);

    /// BunnyPunk function
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
