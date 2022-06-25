pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
/**
 * @title nft reveal version(0.0.1)
 * @author sykang4966@naver.com
 * @notice plus logic
    1. lock
    2. whiteList
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GelmalNftReveal is ERC721 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseUri; // 최종이미지 url(dir)
    string public baseExtension = ".json"; // 파일명
    string public notRevealedUri; // 개봉전 url(dir)

    uint256 public price; //민팅 가격
    uint256 public maxSupply; // 민팅 총공급량수
    uint256 public maxMintAmount; // 한번에 살수 있는 민팅
    uint256 public maxMintPerSale; // 개인이 살수 있는 민팅

    bool public revealed = false; // 리빌여부
    bool public publicMintEnabled = false; // 민팅 가능 여부
    bool public lockNft = false; // 판매 락

    mapping(address => bool) whiteList; // vip

    address private owner = address(0); // creator
    address private admin; // user

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    // modifier
    modifier onlyAdminAndOwner() {
        require( admin == msg.sender || owner == msg.sender  , "Only admin & owner can call this.");
        _;
    }
    modifier onlyOwner() {
        require( owner == msg.sender, "Only owner can call this");
        _;
    }

    // internal
    function getBaseUri() internal view virtual returns (string memory) {
        return baseUri;
    }

    // public method
    function getBalance() public view
    returns (uint256){
        return address(this).balance;
    }

    function getLastTokenId() public view
    returns (uint256) {
        return _tokenIds.current();
    }

    function getAdmin() public view
    returns (address) {
        return admin;
    }

    function getOwner() public view
    returns (address) {
        return owner;
    }

    function withdraw(uint256 _price, address _receiver) public payable onlyOwner {
        (bool success, ) = _receiver.call{value: _price}("");
        require(success, "Failed to send to Wallet receiver");
    }

    function isUserWhiteList(address _user) public view
    returns (bool){
        return whiteList[_user];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(lockNft == true);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function publicMint(uint256 _requestedAmount) public payable {
        uint256 tokenId = _tokenIds.current();
        require(publicMintEnabled, "The public sale is not enabled!"); // 민팅 가능 여부
        require(tokenId + _requestedAmount <= maxSupply + 1, "Exceed max amount"); // 민팅 총 갯수
        require(_requestedAmount > 0 && _requestedAmount <= maxMintAmount, "Too many requests or zero request"); // 최대 구매량 (한번의 tx)
        require(msg.value == price * _requestedAmount, "Not enough eth"); // 이더 잔고부
        require(balanceOf(msg.sender) + _requestedAmount <= maxMintPerSale, "Exceed max amount per person");

        for (uint256 i = 1; i <= _requestedAmount; i++) {
            _safeMint(msg.sender, tokenId + i);
            _tokenIds.increment();
        }
    }

    function whiteListSale(uint256 _requestedAmount) public payable {
        uint256 tokenId = _tokenIds.current();
        require(isUserWhiteList(msg.sender), "this address is not whitelist user"); // 화리 등록 여부
        require(publicMintEnabled, "The public sale is not enabled!"); // 민팅 가능 여부
        require(tokenId + _requestedAmount <= maxSupply + 1, "Exceed max amount"); // 민팅 총 갯수
        require(_requestedAmount > 0 && _requestedAmount <= maxMintAmount, "Too many requests or zero request"); // 최대 구매량 (한번의 tx)
        require(msg.value == price * _requestedAmount, "Not enough eth"); // 이더 잔고부
        require(balanceOf(msg.sender) + _requestedAmount <= maxMintPerSale, "Exceed max amount per person");

        for (uint256 i = 1; i <= _requestedAmount; i++) {
            _safeMint(msg.sender, tokenId + i);
            _tokenIds.increment();
        }
    }

    function airDropMint(address _receiver, uint256 _requestedCount) public onlyAdminAndOwner {
        require(_requestedCount > 0, "zero request");
        uint256 tokenId = _tokenIds.current();
        for (uint256 i = 1; i <= _requestedCount; i++) {
            _mint(_receiver, tokenId + i);
            _tokenIds.increment();
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override
    returns (string memory) {
        if (!revealed) {// 개별 민팅여부에 따라 가능하게
            return bytes(notRevealedUri).length > 0
            ? string(abi.encodePacked(notRevealedUri, _tokenId.toString(), baseExtension))
            : "";
        }

        return bytes(getBaseUri()).length > 0
        ? string(abi.encodePacked(getBaseUri(), _tokenId.toString(), baseExtension))
        : "";
    }

    //only admin&owner method
    function setAdmin(address _adminReceiver) public onlyOwner {
        admin = _adminReceiver;
    }

    //util
    function setRevealed(bool _revealed) public onlyAdminAndOwner {
        revealed = _revealed;
    }

    function setLockNFT(bool _lockNft) public onlyAdminAndOwner {
        lockNft = _lockNft;
    }

    function setPublicMintEnable(bool _publicMintEnabled) public onlyAdminAndOwner {
        publicMintEnabled = _publicMintEnabled;
    }

    function setPrice(uint256 _price) public onlyAdminAndOwner {
        price = _price;
    }

    function setFee(uint256 _fee) public onlyAdminAndOwner {
        transferFee = _fee;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyAdminAndOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyAdminAndOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerSale(uint256 _maxMintPerSale) public onlyAdminAndOwner {
        maxMintPerSale = _maxMintPerSale;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyAdminAndOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseUri(string memory _baseUri) public onlyAdminAndOwner {
        baseUri = _baseUri;
    }

    function setBaseExtension(string memory _baseExtension) public onlyAdminAndOwner {
        baseExtension = _baseExtension;
    }

    function addUserWhiteList(address _receiver) public onlyAdminAndOwner {
        whiteList[_receiver] = true;
    }

    function removeUserWhitelist(address _receiver) public onlyAdminAndOwner {
        whiteList[_receiver] = false;
    }

    function setAll(
        string memory _baseUri, string memory _notRevealedURI,
        bool _revealed, bool _lockNft, bool _publicMintEnabled,
        uint256 _price, uint256 _maxSupply, uint256 _maxMintAmount, uint256 _maxMintPerSale) public onlyAdminAndOwner {

        baseUri = _baseUri;
        notRevealedUri = _notRevealedURI;
        revealed = _revealed;
        lockNft = _lockNft;
        publicMintEnabled = _publicMintEnabled;
        price = _price;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        maxMintPerSale = _maxMintPerSale;
    }
}