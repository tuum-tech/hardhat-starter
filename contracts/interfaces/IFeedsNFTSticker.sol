//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeedsNFTSticker {
    function isApprovedForAll(address _owner, address _operator) external returns (bool);

    function burnFrom(
        address _owner,
        uint256 _id,
        uint256 _value
    ) external;

    function balanceOf(address _owner, uint256 _id) external returns (uint256);
}
