// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MintNft is ERC721URIStorage, Ownable {
    struct NFTInfo {
        uint256 tokenId;
        string tokenURI;
    }
    using Strings for uint256;
    string private _baseTokenURI;
    uint256 private _fee;
    mapping(address => uint256) private _tokenId; // mapping to store latest token ID for each user
    mapping(uint256 => bool) private _authorizedTransfer;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI,
        uint256 fee
    ) ERC721(_name, _symbol) {
        _baseTokenURI = baseTokenURI;
        _fee = fee;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) external {
        _baseTokenURI = baseTokenURI;
    }

    function getTokenId() private returns (uint256) {
        _tokenId[msg.sender]++; // increment user's token ID
        return
            uint256(
                keccak256(abi.encodePacked(msg.sender, _tokenId[msg.sender]))
            ); // generate unique token ID
    }

    function mintNFT(uint256 _count, string memory tokenURI) external payable {
        require(_count > 0, "Invalid input");
        require(msg.value == _fee * _count, "Insufficient payment");

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = getTokenId();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, tokenURI);
        }
    }

    function setMintFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

    function getMintFee() external view returns (uint256) {
        return _fee;
    }

    function getNFTInfo(
        uint256 tokenId
    ) external view returns (address owner, string memory tokenURI) {
        require(_exists(tokenId), "Token ID does not exist");
        owner = ownerOf(tokenId);
        tokenURI = ERC721URIStorage.tokenURI(tokenId);
    }

    function getMyNFTs() external view returns (NFTInfo[] memory) {
        NFTInfo[] memory nftInfos = new NFTInfo[](_tokenId[msg.sender]);

        for (uint256 i = 1; i <= _tokenId[msg.sender]; i++) {
            uint256 tokenId = uint256(
                keccak256(abi.encodePacked(msg.sender, i))
            );
            nftInfos[i - 1] = NFTInfo(
                tokenId,
                ERC721URIStorage.tokenURI(tokenId)
            );
        }

        return nftInfos;
    }

    receive() external payable {}

    fallback() external payable {}
}
