pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/pbmc.sol";
import "../src/fractionNFT.sol";
import "../src/basicERC721.sol";

contract test_fraction is Test {
    GLDToken public FractionERC20;
    MyToken public ERC721Token;
    fractionalNFT public fractionContract;
    AuctionFraction intializeAuctionContract;

    function setUp() external {
        vm.startPrank(address(1));
        ERC721Token = new MyToken();
        fractionContract = new fractionalNFT();
        vm.stopPrank();
    }

    function testMint() external payable {
        vm.startPrank(address(1));
        FractionERC20 = new GLDToken();
        ERC721Token.safeMint(address(1));
        FractionERC20.setOwner(address(fractionContract));
        console.log(FractionERC20.owner());
        fractionContract.setTokenAddr(address(FractionERC20));
        ERC721Token.approve(address(fractionContract), 0);
        fractionContract.setNftForFraction(
            address(ERC721Token),
            0,
            0,
            5,
            address(1)
        );
        address = payable(address(fractionContract));
        deal(address(1), 100 ether);
        fractionContract.BuyFractionNFT{value: 5 ether}();
        console.log(address(fractionContract).balance);
        console.log(fractionContract.fractionsLeft());
        console.log(FractionERC20.balanceOf(address(1)));
        fractionContract.withdrawEth();
        fractionContract.setAuctionProcess();
        FractionERC20.approve(address(fractionContract), 5 * 10 ** 18);
        fractionContract.depositFractionsForSell(3 * 10 ** 18);
        address auctionContract = fractionContract.initializeAuction(
            0,
            1694159415
        );
        vm.warp(1694159414);
        vm.stopPrank();
        deal(address(2), 100 ether);
        vm.startPrank(address(2));
        AuctionFraction(payable(auctionContract)).bid{value: 2 ether}();
        deal(address(3), 100 ether);
        vm.stopPrank();
        vm.startPrank(address(3));
        AuctionFraction(payable(auctionContract)).bid{value: 3 ether}();
        console.log(AuctionFraction(payable(auctionContract)).test());
        vm.stopPrank();
        vm.warp(1694159416);
        vm.prank(address(3));
        AuctionFraction(payable(auctionContract)).claimNFT();
        vm.startPrank(address(1));
        AuctionFraction(payable(auctionContract)).sendEtherToFractionContract();
        fractionContract.endAuctionAndClaimEth(3 ether);
        fractionContract.claimETH();
    }
}
