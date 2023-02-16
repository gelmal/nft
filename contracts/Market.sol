// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Market is Ownable, EIP712, ERC2981 {

    uint256 marketFee = 300;
    address feeAccount;

    constructor(address _feeAccount, string memory _signingDomain, string memory _version)
    EIP712(_signingDomain, _version)  {
        feeAccount = _feeAccount;
    }

    struct Listing {
        address collection;
        address seller;
        address tokenId;
        uint256 price;
        bytes signature;
    }

    //setter
    function makeTransfer(address collection, address to, uint256 tokenId) public onlyOwner{
        IERC721(collection).transferFrom(msg.sender, to, tokenId);
    }

    function modifyFeeAccount(address account) public onlyOwner {
        feeAccount = account;
    }

    function checkIsApprovedForAll(address collection, address owner, address operator) internal view returns(bool){
        return IERC721(collection).isApprovedForAll(owner, operator);
    }

    function makeMarketTrade(address collection, Listing calldata voucher, uint256 tokenId) public payable {
        address signer = _verify(voucher);
        require(signer == callOwnerOf(collection, tokenId), "incorrect voucher");
        require(checkIsApprovedForAll(collection, signer, address(this)), "do not have permission.");
        require(msg.value >= voucher.price, "Insufficient funds to buy");

        uint256 Fee = msg.value * marketFee / 10000;

        (bool success1,) = payable(feeAccount).call{value : Fee}("");
        require(success1, "Failed to remit for signer");

        (bool success2,) = payable(signer).call{value : msg.value-Fee}("");
        require(success2, "Failed to remit for signer");

        IERC721(collection).transferFrom(signer, msg.sender, tokenId);
    }

    //getter

    function callOwnerOf(address collection, uint256 tokenId) public view returns(address owner) {
        return IERC721(collection).ownerOf(tokenId);
    }
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    function _hash(Listing calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("NFTVoucher(address collection,address seller,address tokenId,uint256 price)"),
                voucher.collection,
                voucher.seller,
                voucher.tokenId,
                voucher.price
            )));
    }
    function _verify(Listing calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
    function getRoyaltyInfo(address collection, uint256 tokenId, uint256 salePrice) internal view returns (address, uint256) {
        return IERC2981(collection).royaltyInfo(tokenId, salePrice);
    }

}
