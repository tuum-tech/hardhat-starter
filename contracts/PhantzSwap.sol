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
    IOldBunnyPunk public oldBunnyPunk;
    INewBunnyPunk public newBunnyPunk;
    uint256 public mintedBunnyBunks;
    string private baseURI;

    // Events
    event NewBunnyPunksMinted(address _to, uint256 _mintedBunnyPunks, uint256 _blockNumber);
    event Swapped(uint256 _tokenId, address _user, uint256 _blockNumber);
    event BatchSwapped(uint256[] _tokenIds, address _user);
    event BunnyPunkOwnerShipTransfered(address _enwOwner, uint256 blockNumber);
    event BunnyPunkTransfered(uint256 _tokenId, address _from, address _to, uint256 blockNumber);
    event SetApprovalOldBunnyPunk(address _user, bool _approved, uint256 blockNumber);
    event WithdrawRemainingBalance(address _to, uint256 _balance, uint256 blockNumber);

    constructor(
        IOldBunnyPunk _oldBunnyPunk,
        INewBunnyPunk _newBunnyPunk,
        string memory _baseURI
    ) {
        require(address(_oldBunnyPunk) != address(0), 'Invalid old Buunny Punk');
        require(address(_newBunnyPunk) != address(0), 'Invalid new Buunny Punk');

        oldBunnyPunk = _oldBunnyPunk;
        newBunnyPunk = _newBunnyPunk;
        baseURI = _baseURI;
    }

    function _tokenURI(uint256 _tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId, '.json'));
    }

    /// @dev mint new BunnyPunk
    /// @param _to address that will receive minted BunnyPunk
    /// @param _tokenID tokenID
    /// @notice internal function to mint new BunnyPunk
    function _mint(address _to, uint256 _tokenID) internal {
        (bool success, ) = address(newBunnyPunk).call{value: newBunnyPunk.platformFee()}(
            abi.encodeWithSignature('mint(addres,string)', _to, _tokenURI(_tokenID))
        );
        require(success, 'Mint Failed');
    }

    /// @dev mintNewBunnyPunksForSwap from 1 ~ 690
    /// @notice before call this function, the ownership of new BunnyPunk should be transferred to this address
    function mintNewBunnyPunksForSwap() external onlyOwner {
        require(newBunnyPunk.totalSupply() == 0, 'New BunnyPunk already minted');

        require(
            address(this).balance >= (newBunnyPunk.platformFee()) * 690,
            'Insufficient funds to mint'
        );
        for (uint256 i = 0; i < 690; i++) {
            _mint(address(this), i);
        }
        mintedBunnyBunks = 690;

        emit NewBunnyPunksMinted(address(this), mintedBunnyBunks, block.number);
    }

    /// @dev setApprovalOldBunnyPunksForAll
    /// @param _approved status of approve or not
    /// @notice user will approve this swap contract
    function setApprovalOldBunnyPunksForAll(bool _approved) external {
        oldBunnyPunk.setApprovalForAll(address(this), _approved);

        emit SetApprovalOldBunnyPunk(msg.sender, _approved, block.number);
    }

    /// @dev mint new BunnyPunk
    function mint() external payable {
        require(newBunnyPunk.totalSupply() >= 690, 'mintNewBunnyPunksForSwap not called yet');
        require(newBunnyPunk.totalSupply() <= 2280, 'All PunnyPunks are mintted');

        uint256 platformFee = newBunnyPunk.platformFee();
        require(msg.value >= platformFee, 'Insufficient funds to mint.');

        _mint(msg.sender, mintedBunnyBunks);
        mintedBunnyBunks++;

        emit NewBunnyPunksMinted(address(this), 1, block.number);
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
    /// @notice revoke BunnyPunkOwnership after mint 690 inital BunnyPunks
    function transferNewBunnyPunkOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Invalid User');
        newBunnyPunk.transferOwnership(_newOwner);

        emit BunnyPunkOwnerShipTransfered(_newOwner, block.number);
    }

    /// @dev withdrawRemainingEther
    /// @notice this will withdraw all remaining ether
    function withdrawRemainingEther(address payable _to) external onlyOwner {
        require(_to != address(0), 'Invalid address');

        uint256 remainingBalance = address(this).balance;
        (bool success, ) = _to.call{value: remainingBalance}('');
        require(success, 'Transfer failed');

        emit WithdrawRemainingBalance(_to, remainingBalance, block.number);
    }
}
