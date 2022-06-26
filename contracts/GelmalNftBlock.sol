pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT
// @title nft 대량 민팅
// @notice: nft mass publishing
// @version : 1.0
// @author sykang4966@naver.com

contract GelmalNftBlock is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private baseUri = "";

    constructor(string memory _baseUri) ERC721("BerithNFT", "BNFT") {
        baseUri = _baseUri;
    }

    // minting
    function blockMintNft(uint256 _requestedCount) public onlyOwner{
        require(_requestedCount > 0, "zero request");
        uint256 nowTokenIds = _tokenIds.current();

        for (uint256 i = 1; i < _requestedCount + 1; i++) {
            _mint(msg.sender, nowTokenIds + i);
            _tokenIds.increment();
        }
    }

    // setter
    function setBaseUri(string memory _URI) public onlyOwner{
        baseUri = _URI;
    }

    // getter
    function getBaseUri() public view
    returns (string memory) {
        return baseUri;
    }

    function getTokenIds()
    public view
    returns (uint256) {
        return _tokenIds.current();
    }
}