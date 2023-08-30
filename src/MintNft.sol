// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MyNFT is ERC721URIStorage, Ownable {
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

    function authorizeTransfer(uint256 tokenId) external {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Unauthorized");
        require(!_authorizedTransfer[tokenId], "Already authorized");

        _authorizedTransfer[tokenId] = true;
    }

    // function transferFrom(address from, address to, uint256 tokenId) public virtual override   {
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "transfer caller is not owner nor approved");
    //     require(ownerOf(tokenId) == from, "transfer of token that is not own");
    //     require(to != address(0), "transfer to the zero address");
    //     require(_authorizedTransfer[tokenId] || _msgSender() == owner(), "Unauthorized transfer");

    //     _authorizedTransfer[tokenId] = false; // reset the authorization flag
    //     super.transferFrom(from, to, tokenId);
    // }

    function setMintFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

    function getMintFee() external view returns (uint256) {
        return _fee;
    }

    receive() external payable {}

    fallback() external payable {}
}
