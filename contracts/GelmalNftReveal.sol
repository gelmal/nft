pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title nft reveal version(0.0.1)
 * @author sykang4966@naver.com
 */
contract GelmalNft is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string public baseURI; // after reveal image dir url
    string public baseExtension = ".json"; // file extension
    string public notRevealedUri; // before reveal image dir url

    uint256 public price = 0.05 ether; // minting price
    uint256 public maxSupply; // nft total supply in this contract
    uint256 public maxMintAmount; // number of purchases in one tx
    uint256 public maxMintPerSale; // number of purchases per person

    bool public paused = false; // minting pause
    bool public revealed = false; // able reveal
    bool public publicMintEnabled = false; // able minting

    mapping(address => bool) public whitelisted;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) { }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function publicMint(uint256 _requestedAmount) public payable {
        uint256 supply = totalSupply();
        require(publicMintEnabled, "The public sale is not enabled!");
        require(!paused, "now mint paused");
        require(supply + _requestedAmount <= maxSupply + 1, "Exceed max amount"); // 민팅 총 갯수
        require(_requestedAmount > 0 && _requestedAmount <= maxMintAmount, "Too many requests or zero request"); // 최대 구매량 (한번의 tx)
        require(msg.value == price * _requestedAmount, "Not enough eth"); // 이더 잔고부
        require(balanceOf(msg.sender) + _requestedAmount <= maxMintPerSale, "Exceed max amount per person");

        for (uint256 i = 1; i <= _requestedAmount; i++) {
            _safeMint(msg.sender, supply+i);
        }
    }
    function walletOfOwner(address _owner) public view
    returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function tokenURI(uint256 _tokenId) public view virtual override
    returns (string memory)	{

        if(revealed == false) {
            return bytes(notRevealedUri).length > 0
            ? string(abi.encodePacked(notRevealedUri, _tokenId.toString(), baseExtension))
            : "";
        }

        return bytes(_baseURI()).length > 0
        ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), baseExtension))
        : "";
    }

    //only owner method

    function reveal() public onlyOwner {
        revealed = true;
    }
    function startSale() public onlyOwner {
        publicMintEnabled = true;
    }
    function endSale() public onlyOwner {
        publicMintEnabled = false;
    }
    function airDropMint(address _recipient, uint256 _requestedCount) public onlyOwner{
        require(_requestedCount > 0, "zero request");
        for(uint256 i = 0; i < _requestedCount; i++) {
            uint256 supply = totalSupply();
            _mint(_recipient, supply+1);
        }
    }
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
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }
}