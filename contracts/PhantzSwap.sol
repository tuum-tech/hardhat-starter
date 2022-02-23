//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////
/// @title PhantzSwap
/// @author Tuum-Tech
////////////////////////////////////////////////////////////////////////////////////////////

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOldBunnyPunk.sol';
import './interfaces/INewBunnyPunk.sol';

contract PhantzSwap is Ownable {
    IOldBunnyPunk oldBunnyPunk;
    INewBunnyPunk newBunnyPunk;
    bool public isNewBunnyPunkMinted;

    // Events
    event NewBunnyPunksMinted(address _to, uint256 _mintedNFTs, uint256 _blockNumber);
    event Swapped(uint256 _tokenId, address _user, uint256 _blockNumber);
    event BatchSwapped(uint256[] _tokenIds, address _user);
    event BunnyPunkOwnerShipTransfered(address _enwOwner, uint256 blockNumber);
    event BunnyPunkTransfered(uint256 _tokenId, address _from, address _to, uint256 blockNumber);
    event SetApprovalOldBunnyPunk(address _user, bool _approved, uint256 blockNumber);

    constructor(IOldBunnyPunk _oldBunnyPunk, INewBunnyPunk _newBunnyPunk) {
        require(address(_oldBunnyPunk) != address(0), 'Invalid old Buunny Punk');
        require(address(_newBunnyPunk) != address(0), 'Invalid new Buunny Punk');
        oldBunnyPunk = _oldBunnyPunk;
        newBunnyPunk = _newBunnyPunk;
    }

    /// @dev setApprovalOldNFTsForAll
    /// @param _approved status of approve or not
    /// @notice user will approve this swap contract
    function setApprovalOldNFTsForAll(bool _approved) external {
        oldBunnyPunk.setApprovalForAll(address(this), _approved);

        emit SetApprovalOldBunnyPunk(msg.sender, _approved, block.number);
    }

    /// @dev mintNewBunnyPunks from 1 ~ 690
    /// @param _tokenUris the array of token URIs
    /// @notice before call this function, the ownership of new BunnyPunk should be transferred to this address
    /// this function should be called before any mints of new BunnyPunk to match token IDs from 1 ~ 690
    /// after this function is successfully called, transferNewBunnyPunkOwnership function should be called to revote ownership of new BunnyPunk
    function mintNewBunnyPunks(string[] memory _tokenUris) external onlyOwner {
        require(_tokenUris.length == 690, 'Invalid Data');
        require(!isNewBunnyPunkMinted, 'Already minted');
        require(newBunnyPunk.totalSupply() == 0, 'New BunnyPunk already minted');

        uint256 index;
        for (index = 1; index <= 690; index++) {
            newBunnyPunk.mint(address(this), _tokenUris[index]);
        }
        isNewBunnyPunkMinted = true;

        emit NewBunnyPunksMinted(address(this), index, block.number);
    }

    /// @dev batchSwap BunnyPunks
    /// @param _tokenIds to be swapped
    function batchSwap(uint256[] memory _tokenIds) external {
        require(_tokenIds.length > 0, 'Invalid TokenIds');
        require(oldBunnyPunk.isApprovedForAll(msg.sender, address(this)), 'Not approved yet');

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            swap(_tokenIds[i], msg.sender);
        }

        emit BatchSwapped(_tokenIds, msg.sender);
    }

    /// @dev swap one BunnyPunk
    /// @param _tokenId to be swapped
    /// @param _user address of user who is swapping BunnyPunks
    /// @notice this swap contract should have new BunnyPunk to be swapped
    /// user should call ERC721.setApprovealForAll() first so that this swap contract can use their old BunnyPunks
    function swap(uint256 _tokenId, address _user) public {
        require(_user != address(0), 'Invalid user');
        require(
            newBunnyPunk.ownerOf(_tokenId) == address(this),
            'No new BunnyPunk for this TokenId'
        );
        require(oldBunnyPunk.isApprovedForAll(msg.sender, address(this)), 'Not approved yet');

        // transfer old BunnyPunk to null address
        oldBunnyPunk.transferFrom(_user, address(0), _tokenId);

        // transfer new BunnyPunk to
        newBunnyPunk.transferFrom(address(this), _user, _tokenId);

        emit Swapped(_tokenId, _user, block.number);
    }

    /// @dev transferNewBunnyPunk
    /// @notice this will transfer unswaped new BunnyPunk
    function transferNewBunnyPunk(uint256 _tokenId, address _to) public onlyOwner {
        require(
            newBunnyPunk.ownerOf(_tokenId) == address(this),
            'No new BunnyPunk for this tokenID'
        );
        require(_to != address(0), 'Invalid User');

        newBunnyPunk.transferFrom(address(this), _to, _tokenId);
        emit BunnyPunkTransfered(_tokenId, address(this), _to, block.number);
    }

    /// @dev transferNewBunnyPunkOwnership
    /// @notice revoke BunnyPunkOwnership after mint 690 inital NFTs
    function transferNewBunnyPunkOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Invalid User');
        newBunnyPunk.transferOwnership(_newOwner);

        emit BunnyPunkOwnerShipTransfered(_newOwner, block.number);
    }
}
