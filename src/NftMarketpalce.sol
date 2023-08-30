// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    mapping(address => uint256) private _tokenId;
    uint256 private _serviceFee; // percent * 100, e.g. 2500 is 25.00%
    mapping(uint256 => bool) private _listed;
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => uint256) private _tokenPrices;
    mapping(uint256 => string) private _tokenURIs;

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

    function list(
        uint256[] memory prices,
        string[] memory tokenURIs
    ) external payable {
        IERC721 token = IERC721(msg.sender);
        require(prices.length == tokenURIs.length, "Invalid input");

        uint256 userTokenId = _tokenId[msg.sender]; // get user's starting token ID
        for (uint256 i = 0; i < prices.length; i++) {
            userTokenId++; // increment user's token ID
            uint256 tokenId = uint256(
                keccak256(abi.encodePacked(msg.sender, userTokenId))
            ); // generate unique token ID

            require(!_listed[tokenId], "Already listed");

            token.safeTransferFrom(msg.sender, address(this), tokenId);
            _listed[tokenId] = true;
            _tokenOwners[tokenId] = msg.sender;
            _tokenPrices[tokenId] = prices[i];
            _tokenURIs[tokenId] = tokenURIs[i];

            emit Listed(msg.sender, tokenId, prices[i]);
        }

        _tokenId[msg.sender] = userTokenId; // store user's latest token ID
    }

    function unlist(uint256 tokenId) external {
        require(_listed[tokenId], "Not listed");
        require(_tokenOwners[tokenId] == msg.sender, "Unauthorized");

        IERC721 token = IERC721(msg.sender);
        token.safeTransferFrom(address(this), msg.sender, tokenId);
        _listed[tokenId] = false;
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokenURIs[tokenId] = "";

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
        _tokenURIs[tokenId] = "";

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

    function getTokenURI(
        uint256 tokenId
    ) external view returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
