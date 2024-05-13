// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {console} from "forge-std/Test.sol";

import "./BaseERC20.sol";
import "./BaseERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "./interface/IDomain.sol";

//Write a simple NFT market contract, using your own issued Token to buy and sell NFTs. The functions include:

// list(): Implement the listing function, where the NFT holder can set a price
// (how many tokens are needed to purchase the NFT) and list the NFT on the NFT market.
// buyNFT(): Implement the purchase function for NFTs,
// where users transfer the specified token quantity and receive the corresponding NFT.
contract NFTMarketV2 is EIP712 {
    struct listOfNFTs {
        uint256 price;
        address seller;
    }
    BaseERC20 tokenContract;
    BaseERC721 nftContract;

    // tokenId => ListOfNFTS
    mapping(address => mapping(uint256 => listOfNFTs)) public listings;

    event Listed(
        address indexed nftca,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event Bought(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );

    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    error InvalidSigner(address signer,address owner);
    error ExpiredSignature(uint256 deadLine );
    constructor() EIP712("rain", "1") {}

    function _DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function pricceOfListings(
        address nftCA,
        uint256 tokenId
    ) external view returns (uint256) {
        return listings[nftCA][tokenId].price;
    }

    function ownerOfListings(
        address nftCA,
        uint256 tokenId
    ) external view returns (address) {
        return listings[nftCA][tokenId].seller;
    }

    function list(address nftAddress, uint256 tokenId, uint256 price) public {
        nftContract = BaseERC721(nftAddress);
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "You are not the owner"
        );
        require(price > 0, "price must be greater than 0");
        listings[nftAddress][tokenId].seller = msg.sender;
        listings[nftAddress][tokenId].price = price;
        nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Listed(nftAddress, tokenId, msg.sender, price);
    }

    function buy(
        uint256 tokenId,
        address _tokenAdress,
        address _nftAdress
    ) public {
        tokenContract = BaseERC20(_tokenAdress);
        nftContract = BaseERC721(_nftAdress);
        listOfNFTs memory listing = listings[_nftAdress][tokenId];
        require(listing.price > 0, "this is not for sale");
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "already selled"
        );
        tokenContract.transferFrom(msg.sender, listing.seller, listing.price);
        nftContract.transferFrom(address(this), msg.sender, tokenId);
        delete listings[_nftAdress][tokenId];
        emit Bought(tokenId, msg.sender, listing.seller, listing.price);
    }

    bytes32 private immutable _PERMIT_TYPEHAS =
        keccak256(
            "Permit(address owner, address spender,uint256 value,uint256 deadline)"
        );

    struct SignModal {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _isWhite(
        address contractAddress,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        nftContract = BaseERC721(contractAddress);
        address nft_owner = nftContract.owner();
        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                nft_owner,
                msg.sender,
                tokenId,
                tokenId,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                nftContract.DOMAIN_SEPARATOR(),
                hashStruct
            )
        );
        address signer = ecrecover(digest, v, r, s);

        require(signer == nft_owner, "Invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");

        require(block.timestamp < deadline, "Signed transaction expired");
    }

    function permitBuy(
        address nftAddress,
        uint256 tokenId,
        address erc20Address,
        address _owner,
        address spender,
        uint256 _value,
        uint256 deadline,
        SignModal memory sign1,
        SignModal memory sign2
    ) external {
        _isWhite(nftAddress, tokenId, deadline, sign1.v, sign1.r, sign1.s);
        _permitBuy(
            nftAddress,
            tokenId,
            erc20Address,
            _owner,
            spender,
            _value,
            deadline,
            sign2.v,
            sign2.r,
            sign2.s
        );
    }

    function _permitBuy(
        address _nftAddress,
        uint256 tokenId,
        address erc20Adress,
        address _owner,
        address spender,
        uint256 _value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        BaseERC20(erc20Adress).permit(
            _owner,
            spender,
            _value,
            deadline,
            v,
            r,
            s
        );
        buy(tokenId, erc20Adress, _nftAddress);
    }

    function permitList(
        address owner,
        address spender,
        address contractAddress,
        uint256 price,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _permitList(
            owner,
            spender,
            contractAddress,
            price,
            tokenId,
            deadline,
            v,
            r,
            s
        );
    }

    function _permitList(
        address owner,
        address spender,
        address contractAddress,
        uint256 price,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // NFTContract = new NFTContract()
        nftContract = BaseERC721(contractAddress);
        _permitVaild(owner, spender, tokenId, deadline, v, r, s);

        list(contractAddress, tokenId, price);
    }

    function _permitVaild(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ExpiredSignature(deadline);
        }
        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, value, deadline)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert InvalidSigner(signer, owner);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
