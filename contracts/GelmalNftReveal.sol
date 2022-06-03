pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT
/**
 * @title nft reveal version(0.0.1)
 * @author sykang4966@naver.com
 */

contract GelmalNftReveal is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI; // 최종이미지 url(dir)
    string public baseExtension = ".json"; // 파일명
    string public notRevealedUri; // 개봉전 url(dir)

    uint256 public price = 0.05 ether; //민팅 가격
    uint256 public maxSupply; // 민팅 총공급량수
    uint256 public maxMintAmount; // 한번에 살수 있는 민팅
    uint256 public maxMintPerSale; // 개인이 살수 있는 민팅

    bool public revealed = false; // 리빌여부
    bool public publicMintEnabled = false; // 민팅 가능 여부
    bool public lockNft = false; // lock

    mapping(address => bool) whitelisted;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) { }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public method

    function getContractBalance() public view
    returns(uint256){
        return address(this).balance;
    }

    function getYesOrNoWhiteList(address _user) public view
    returns (bool){
        return whitelisted[_user];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(lockNft == true);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function publicMint(uint256 _requestedAmount) public payable {
        uint256 nowTokenIds = _tokenIds.current();
        require(publicMintEnabled, "The public sale is not enabled!"); // 민팅 가능 여부
        require(nowTokenIds + _requestedAmount <= maxSupply + 1, "Exceed max amount"); // 민팅 총 갯수
        require(_requestedAmount > 0 && _requestedAmount <= maxMintAmount, "Too many requests or zero request"); // 최대 구매량 (한번의 tx)
        require(msg.value == price * _requestedAmount, "Not enough eth"); // 이더 잔고부
        require(balanceOf(msg.sender) + _requestedAmount <= maxMintPerSale, "Exceed max amount per person");

        for (uint256 i = 1; i <= _requestedAmount; i++) {
            _safeMint(msg.sender, nowTokenIds + 1);
            _tokenIds.increment();
        }
    }
    function whiteListSale(uint256 _requestedAmount) public payable {
        uint256 nowTokenIds = _tokenIds.current();
        require(getYesOrNoWhiteList(msg.sender), "this address is not whitelist user");
        require(publicMintEnabled, "The public sale is not enabled!"); // 민팅 가능 여부
        require(nowTokenIds + _requestedAmount <= maxSupply + 1, "Exceed max amount"); // 민팅 총 갯수
        require(_requestedAmount > 0 && _requestedAmount <= maxMintAmount, "Too many requests or zero request"); // 최대 구매량 (한번의 tx)
        require(msg.value == price * _requestedAmount, "Not enough eth"); // 이더 잔고부
        require(balanceOf(msg.sender) + _requestedAmount <= maxMintPerSale, "Exceed max amount per person");

        for (uint256 i = 1; i <= _requestedAmount; i++) {
            _safeMint(msg.sender, nowTokenIds + 1);
            _tokenIds.increment();
        }
    }
    function airDropMint(address _reciever, uint256 _requestedCount) public onlyOwner{
        require(_requestedCount > 0, "zero request");
        uint256 nowTokenIds = _tokenIds.current();
        for(uint256 i = 0; i < _requestedCount; i++) {
            _mint(_reciever, nowTokenIds + i);
            _tokenIds.increment();
        }
    }
    function tokenURI(uint256 _tokenId) public view virtual override
    returns (string memory)	{
        if(revealed == false) { // 개별 민팅여부에 따라 가능하게
            return bytes(notRevealedUri).length > 0
            ? string(abi.encodePacked(notRevealedUri, _tokenId.toString(), baseExtension))
            : "";
        }

        return bytes(_baseURI()).length > 0
        ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), baseExtension))
        : "";
    }

    //only owner method

    //util
    function reveal(bool _type) public onlyOwner {
        revealed = _type;
    }
    function setLockNft(bool _type) public onlyOwner {
        lockNft = _type;
    }
    function setSaleState(bool _type) public onlyOwner {
        publicMintEnabled = _type;
    }
    /**
     * title set public sale
     * param uint256 _maxSupply : max amount of minting
     * param uint256 _maxMintAmount : can be bought at one tx
     * param uint256 _maxMintPerSale : can be bought at personal in this contract
    */
    function setupPublicSale(uint256 _price, uint256 _maxSupply, uint256 _maxMintAmount, uint256 _maxMintPerSale) public onlyOwner {
        price = 0.001 ether * _price;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        maxMintPerSale = _maxMintPerSale;
    }
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = 0.001 ether * _newPrice;
    }
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    function setMaxMintPerSale(uint256 _maxMintPerSale) public onlyOwner {
        maxMintPerSale = _maxMintPerSale;
    }
    //url
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    //whitelist
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function withdrawToMe() public payable onlyOwner {
        uint256 amountOfEth = getContractBalance();
        (bool ms, ) = payable(owner()).call{value: amountOfEth}("");
        require(ms);
    }

    function withdrawToOther(uint256 _amount, address _receiver) public payable onlyOwner {
        uint256 amount = 0.001 ether * _amount;
        (bool os, ) = payable(_receiver).call{value: amount}("");
        require(os);
    }
}