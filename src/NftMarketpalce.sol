// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    uint256 private _tokenId;
    uint256 private _serviceFee; // percent * 100, e.g. 2500 is 25.00%
    mapping(uint256 => bool) private _listed;
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => uint256) private _tokenPrices;

    event Listed(address indexed owner, uint256 indexed tokenId, uint256 price);
    event Unlisted(address indexed owner, uint256 indexed tokenId);
    event Sold(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price,
        uint256 serviceFee
    );

    constructor(uint256 serviceFee) {
        _serviceFee = serviceFee;
    }

    function getServiceFee() public view returns (uint256) {
        return _serviceFee;
    }

    function setServiceFee(uint256 serviceFee) external onlyOwner {
        require(serviceFee < 10000, "Invalid input"); // percent * 100
        _serviceFee = serviceFee;
    }

    function list(uint256 tokenId, uint256 price) external payable {
        IERC721 token = IERC721(msg.sender);
        require(token.ownerOf(tokenId) == msg.sender, "Unauthorized");
        require(!_listed[tokenId], "Already listed");

        token.safeTransferFrom(msg.sender, address(this), tokenId);
        _listed[tokenId] = true;
        _tokenOwners[tokenId] = msg.sender;
        _tokenPrices[tokenId] = price;

        emit Listed(msg.sender, tokenId, price);
    }

    function unlist(uint256 tokenId) external {
        require(_listed[tokenId], "Not listed");
        require(_tokenOwners[tokenId] == msg.sender, "Unauthorized");

        IERC721 token = IERC721(msg.sender);
        token.safeTransferFrom(address(this), msg.sender, tokenId);
        _listed[tokenId] = false;
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;

        emit Unlisted(msg.sender, tokenId);
    }

    function buy(uint256 tokenId) external payable {
        require(_listed[tokenId], "Not listed");
        require(_tokenOwners[tokenId] != msg.sender, "Invalid input");

        uint256 price = _tokenPrices[tokenId];
        uint256 serviceFee = (price * _serviceFee) / 10000; // calculate service fee as percent of price
        uint256 amount = price + serviceFee;

        require(msg.value == amount, "Incorrect amount");

        payable(_tokenOwners[tokenId]).transfer(price);
        payable(owner()).transfer(serviceFee); // send service fee to contract owner

        IERC721 token = IERC721(_tokenOwners[tokenId]);
        token.safeTransferFrom(address(this), msg.sender, tokenId);
        _listed[tokenId] = false;
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;

        emit Sold(
            _tokenOwners[tokenId],
            msg.sender,
            tokenId,
            price,
            serviceFee
        );
    }

    function isListed(uint256 tokenId) external view returns (bool) {
        return _listed[tokenId];
    }

    function getTokenPrice(uint256 tokenId) external view returns (uint256) {
        return _tokenPrices[tokenId];
    }
}
