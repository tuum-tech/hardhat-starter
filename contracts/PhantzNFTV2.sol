//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/IFeedsNFTSticker.sol';
import './util/Initializable.sol';

/**
 * @title PhantzNFTV2
 */
contract PhantzNFTV2 is IERC721Receiver, ERC721, Ownable, Initializable {
    using Strings for uint256;

    /// @dev Events of the contract
    event Initialized();
    event Minted(uint256 _tokenId, address _beneficiary, string _tokenUri, address _minter);
    event UpdatePlatformFee(uint256 _platformFee);
    event UpdateFeeRecipient(address payable _feeRecipient);
    event Swapped(address _user, uint256 _oldTokenId, uint256 _newTokenId, uint256 _blockTime);

    address auction;
    address marketplace;
    address bundleMarketplace;
    uint256 private _currentTokenId = 0;

    /// @notice Platform fee
    uint256 public platformFee;

    /// @notice Platform fee receipient
    address payable public feeReceipient;

    /// @notice Feeds NFT Sticker(FSTK), FeedsContractProxy
    IFeedsNFTSticker public feesNFTSticker;

    /// @notice old tokenId => new tokenId
    mapping(uint256 => uint256) private _oldToNewTokenIds;

    /// @notice token amounts to be swapped
    uint256 private immutable swapCount;

    /// @notice Contract constructor
    constructor(
        string memory _name,
        string memory _symbol,
        address _auction,
        address _marketplace,
        address _bundleMarketplace,
        uint256 _platformFee,
        address payable _feeReceipient,
        address _feesNFTSticker,
        uint256 _swapCount
    ) public ERC721(_name, _symbol) {
        auction = _auction;
        marketplace = _marketplace;
        bundleMarketplace = _bundleMarketplace;
        platformFee = _platformFee;
        feeReceipient = _feeReceipient;
        feesNFTSticker = IFeedsNFTSticker(_feesNFTSticker);
        swapCount = _swapCount;
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _feeReceipient payable address the address to sends the funds to
     */
    function updateFeeRecipient(address payable _feeReceipient) external onlyOwner {
        feeReceipient = _feeReceipient;
        emit UpdateFeeRecipient(_feeReceipient);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        return
            string(
                abi.encodePacked(
                    'ipfs://QmUaG9DJMQprYoSWXp3X1V1YMS5E37pjt4MkQGpQtgZkeK/', // baseURI
                    tokenId.toString(),
                    '.json'
                )
            );
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId + 1;
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    /**
     * Override _isApprovedOrOwner to whitelist Fantom contracts to enable gas-less listings.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ERC721.ownerOf(tokenId);
        if (isApprovedForAll(owner, spender)) return true;
        return super._isApprovedOrOwner(spender, tokenId);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mint(address _to) external payable {
        require(_currentTokenId >= swapCount, 'Should mint NFTs for swap first.');
        require(msg.value >= platformFee, 'Insufficient funds to mint.');

        uint256 newTokenId = _getNextTokenId();
        _safeMint(_to, newTokenId);
        _incrementTokenId();

        // Send FTM fee to fee recipient
        (bool success, ) = feeReceipient.call{value: msg.value}('');
        require(success, 'Transfer failed');

        emit Minted(newTokenId, _to, tokenURI(newTokenId), _msgSender());
    }

    /**
    @notice Burns a DigitalaxGarmentNFT, releasing any composed 1155 tokens held by the token itself
    @dev Only the owner or an approved sender can call this method
    @param _tokenId the token ID to burn
    */
    function burn(uint256 _tokenId) external {
        address operator = _msgSender();
        require(
            ownerOf(_tokenId) == operator || isApproved(_tokenId, operator),
            'Only garment owner or approved'
        );

        // Destroy token mappings
        _burn(_tokenId);
    }

    /**
     * @dev checks the given token ID is approved either for all or the single token ID
     */
    function isApproved(uint256 _tokenId, address _operator) public view returns (bool) {
        return isApprovedForAll(ownerOf(_tokenId), _operator) || getApproved(_tokenId) == _operator;
    }

    /**
     * @dev Override isApprovedForAll to whitelist Fantom contracts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist Fantom auction, marketplace, bundle marketplace contracts for easy trading.
        if (auction == operator || marketplace == operator || bundleMarketplace == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev will mint swapCount NFTs for swap
     */
    function initialize(uint256[] memory oldTokenIds) external initializer {
        require(_currentTokenId == 0, 'Some tokens are minted');
        require(oldTokenIds.length == swapCount, 'phantzTokenIDs invalid');

        for (uint256 i = 0; i < swapCount; i++) {
            // pre-mint NFT
            uint256 newTokenId = _getNextTokenId();
            _safeMint(address(this), newTokenId);
            _incrementTokenId();

            // mapping new & old Phantz tokenID
            _oldToNewTokenIds[oldTokenIds[i]] = newTokenId;
        }

        emit Initialized();
    }

    /**
     * @dev swap old swapCount NFTs with new
     */
    function swap(uint256 _oldTokenId) external {
        require(_currentTokenId >= swapCount, 'Should mint NFTs for swap first.');

        uint256 newTokenId = _oldToNewTokenIds[_oldTokenId];
        require(newTokenId > 0 && newTokenId <= swapCount, 'Not swappable tokenID');

        address user = _msgSender();
        require(
            feesNFTSticker.isApprovedForAll(user, address(this)),
            'Should approve contract first'
        );

        require(feesNFTSticker.balanceOf(user, _oldTokenId) > 0, 'No NFT to swap');

        // burn old NFT
        feesNFTSticker.burnFrom(user, _oldTokenId, 1);

        // mint new NFT
        _safeTransfer(address(this), user, newTokenId, '');

        emit Swapped(user, _oldTokenId, newTokenId, block.timestamp);
    }
}
