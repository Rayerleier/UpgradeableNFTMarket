pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {NFTMarketProxy} from "../src/NFTMarketProxy.sol";
import {NFTMarketProxyAdmin} from "../src/NFTMarketProxyAdmin.sol";
import {NFTMarketV1} from "../src/NFTMarketV1.sol";
import {NFTMarketV2} from "../src/NFTMarketV2.sol";
import {Upgrades, Options} from "../openzeppelin-foundry-upgrades/Upgrades.sol";
import {BaseERC20} from "../src/BaseERC20.sol";
import {BaseERC721} from "../src/BaseERC721.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "../src/interface/IDomain.sol";

contract NFTMarketUpgradeTest is Test {
    address proxyAdmin;
    address nftOwner;
    address nftBuyer;
    uint256 constant proxyAdminPrivateKey = 123;
    uint256 constant nftOwnerPrivateKey = 234;
    uint256 constant nftBuyerPrivateKey = 345;
    NFTMarketProxyAdmin nftmarketProxyAdmin;
    NFTMarketProxy nftmarketProxy;
    NFTMarketV1 nftmarketV1;
    NFTMarketV2 nftmarketV2;
    address proxy;
    BaseERC20 erc20;
    BaseERC721 erc721;
    SigUtils sigUtils;
    function setUp() public {
        proxyAdmin = vm.addr(proxyAdminPrivateKey);
        nftOwner = vm.addr(nftOwnerPrivateKey);
        nftBuyer = vm.addr(nftBuyerPrivateKey);
        vm.startPrank(proxyAdmin);
        nftmarketProxy = new NFTMarketProxy();
        erc20 = new BaseERC20("rain", "rayer", 1e18);
        erc721 = new BaseERC721("rain", "rayer", "OK");
        erc721.mint(nftOwner);
        vm.stopPrank();
    }

    function testUpgrade() public {
        uint256 tokenId = 1;
        uint256 price = 100;
        setProxyV1();
        List(tokenId, price); // 用call
        EqPriceAndOwner(tokenId, price);
        setProxyV2();
        tokenId = 2;
        price = 200;
        ListPermit(tokenId, price);
        EqPriceAndOwnerV2(tokenId, price);
    }

    function EqPriceAndOwnerV2(uint256 tokenId, uint256 price) internal {
        (, bytes memory dataOfPrice) = address(proxy).call(
            abi.encodeWithSignature(
                "pricceOfListings(address,uint256)",
                address(erc721),
                tokenId
            )
        );
        uint256 _price = abi.decode(dataOfPrice, (uint256));
        assertEq(_price, price);
        (, bytes memory dataOfOwner) = address(proxy).call(
            abi.encodeWithSignature(
                "ownerOfListings(address,uint256)",
                address(erc721),
                tokenId
            )
        );
        address _owner = abi.decode(dataOfOwner, (address));
        assertEq(_owner, address(nftOwner));
    }

    function ListPermit(uint256 tokenId, uint256 price) internal {
        // vm.startPrank(proxyAdmin);
        // (, bytes memory dataOfDomain) = address(proxy).call(
        //     abi.encodeWithSignature("_DOMAIN_SEPARATOR()")
        // );
        // bytes memory DOMAIN_SEPARATOR = abi.decode(dataOfDomain, (bytes));
        bytes32 DOMAIN_SEPARATOR = IDomain(address(proxy))._DOMAIN_SEPARATOR();
        sigUtils = new SigUtils(DOMAIN_SEPARATOR);
        erc721.mint(nftOwner);
        erc721.mint(nftOwner);
        erc721.mint(nftOwner);
        vm.startPrank(nftOwner);
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: address(nftOwner),
            spender: address(proxy),
            value: tokenId,
            nonce: tokenId,
            deadline: 1 days
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(nftOwnerPrivateKey, digest);
        erc721.setApprovalForAll(address(proxy), true);
        (bool success, ) = address(proxy).call(
            abi.encodeWithSignature(
                "permitList(address,address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)",
                address(nftOwner),
                address(proxy),
                address(erc721),
                price,
                tokenId,
                1 days,
                v,
                r,
                s
            )
        );
        assertTrue(success);
    }

    function setProxyV2() internal {
        vm.startPrank(proxyAdmin);
        Options memory opts;
        //   opts.unsafeSkipAllChecks = true;
        opts.unsafeSkipAllChecks = true;
        opts.referenceContract = "NFTMarketV1.sol:NFTMarketV1";
        proxy = Upgrades.deployTransparentProxy(
            "NFTMarketV2.sol:NFTMarketV2",
            proxyAdmin, // INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN,
            "", // abi.encodeCall(MyContract.initialize, ("arguments for the initialize function")
            opts
        );
        vm.stopPrank();
    }

    function EqPriceAndOwner(uint256 tokenId, uint256 _price) internal {
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSignature(
                "priceOfNFt(address,uint256)",
                address(erc721),
                tokenId
            )
        );
        uint256 price = abi.decode(data, (uint256));
        (, bytes memory dataOfuser) = address(proxy).call(
            abi.encodeWithSignature(
                "ownerOfNFT(address,uint256)",
                address(erc721),
                tokenId
            )
        );
        address owner = abi.decode(dataOfuser, (address));
        assertEq(owner, nftOwner);
        assertEq(price, _price);
    }

    function List(uint256 tokenId, uint256 price) internal {
        vm.startPrank(nftOwner);

        erc721.approve(address(proxy), tokenId);
        (bool suc, ) = proxy.call(
            abi.encodeWithSignature(
                "list(address,uint256,uint256)",
                address(erc721),
                tokenId,
                price
            )
        );
        assertEq(suc, true);
        vm.stopPrank();
    }

    function setProxyV1() internal {
        vm.startPrank(proxyAdmin);
        Options memory opts;
        //   opts.unsafeSkipAllChecks = true;
        opts.unsafeSkipAllChecks = true;
        proxy = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol:NFTMarketV1",
            proxyAdmin, // INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN,
            "", // abi.encodeCall(MyContract.initialize, ("arguments for the initialize function")
            opts
        );
        vm.stopPrank();
    }
}
