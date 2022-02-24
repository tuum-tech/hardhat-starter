// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface INewBunnyPunk {
    /// ERC721 function
    function ownerOf(uint256 tokenId) external returns (address);

    function totalSupply() external returns (uint256);

    /// Ownable function
    function transferOwnership(address newOwner) external;

    /// BunnyPunk function
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function platformFee() external returns (uint256);

    function mint(address _to, string calldata _tokenUri) external;
}
