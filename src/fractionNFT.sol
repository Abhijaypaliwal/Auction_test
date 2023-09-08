// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
// import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
// import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
interface IMyERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function name() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMyERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address _to, uint256 _amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract AuctionFraction {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    bool start;
    mapping(address => uint256) public bidsForAddresses;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public tokenId;
    address addressFractionNFT;

    receive() external payable {}

    modifier onlyOwner() {
        require(owner == msg.sender, "only admin is allowed");
        _;
    }
    IMyERC721 NFTContract;

    constructor(
        address _owner,
        uint256 _startTime,
        uint256 _endTime,
        address _contractAddr,
        uint256 _tokenId,
        address _addressFractionNFT
    ) public {
        owner = _owner;
        startTime = _startTime;
        endTime = _endTime;
        NFTContract = IMyERC721(_contractAddr);
        tokenId = _tokenId;
        addressFractionNFT = _addressFractionNFT;
    }

    function bid() external payable returns (bool) {
        require(msg.value >= highestBid, "bid is less than highest");
        require(startTime <= block.timestamp, "auction not started yet");
        require(endTime >= block.timestamp, "auction has been ended");

        if (bidsForAddresses[msg.sender] == 0) {
            bidsForAddresses[msg.sender] += msg.value;
            highestBid = msg.value;
            highestBidder = msg.sender;
        } else {
            (bool sent, ) = msg.sender.call{
                value: bidsForAddresses[msg.sender]
            }("");
            require(sent, "Failed to send Ether");
            bidsForAddresses[msg.sender] = msg.value;
            highestBid = msg.value;
            highestBidder = msg.sender;
        }
        return true;
    }

    function claimEther() public returns (bool) {
        require(endTime <= block.timestamp, "auction has not ended");
        require(msg.sender != highestBidder, "winner cannot withdraw");
        (bool sent, ) = msg.sender.call{value: bidsForAddresses[msg.sender]}(
            ""
        );
        require(sent, "Failed to send Ether");
        return sent;
    }

    function claimNFT() public returns (bool) {
        require(endTime <= block.timestamp, "auction has not ended");
        require(highestBidder == msg.sender, "only auctionWinner can call");

        NFTContract.transferFrom(address(this), msg.sender, tokenId);
        return true;
    }

    function sendEtherToFractionContract() external onlyOwner returns (bool) {
        require(endTime <= block.timestamp, "auction has not ended");
        (bool sent, ) = addressFractionNFT.call{value: highestBid}("");
        require(sent, "Failed to send Ether");
        return sent;
    }

    function test() external view returns(uint) {
        return highestBid;
    }
}

contract fractionalNFT {
    struct nftDetails {
        address currentOwner;
        uint256 totalSupply;
        address nftContractDetails;
        uint256 nftTokenId;
        bool canTransfer;
        uint256 amtToSellInEth;
        bool setForAuction;
    }

    address public _owner;
    IMyERC20 TokenInstance;
    IMyERC721 NFTinstance;
    uint256 public totalFractions;
    uint256 public fractionsLeft;
    uint256 public forAuctionTokens;
    address public tokenOwner;
    address public auctionContract;
    uint256 public ethAmountByAuction;
    mapping(address => uint256) public depositorsForAuction;

    constructor() {
        _owner = msg.sender;
    }

    receive() external payable {}

    nftDetails details;
    address public tokenAddr;

    modifier onlyOwner() {
        require(_owner == msg.sender, "only owner can call this function");
        _;
    }

    function setTokenAddr(address _addr) external onlyOwner returns (bool) {
        tokenAddr = _addr;
        TokenInstance = IMyERC20(tokenAddr);
        return true;
    }

    /**
     * @notice Set an NFT for fractional ownership.
     * @param _nftContract Address of the NFT contract.
     * @param _tokenID ID of the NFT token.
     * @param _totalsupply Total supply of fractional tokens.
     * @return True if the setup is successful.
     */

    function setNftForFraction(
        address _nftContract,
        uint256 _tokenID,
        uint256 _totalsupply,
        uint256 _amtToSellInEth,
        address _tokenOwner
    ) public onlyOwner returns (bool) {
        NFTinstance = IMyERC721(_nftContract);
        NFTinstance.transferFrom(msg.sender, address(this), _tokenID);
        details.currentOwner = address(this);
        details.totalSupply = _totalsupply;
        details.nftContractDetails = _nftContract;
        details.nftTokenId = _tokenID;
        details.canTransfer = false;
        details.amtToSellInEth = _amtToSellInEth;
        details.setForAuction = false;
        totalFractions = _amtToSellInEth * (10**18);
        fractionsLeft = totalFractions;
        tokenOwner = _tokenOwner;
        return true;
    }

    /**
     * @notice Buy fractional ownership of the NFT.
     * @return True if the purchase is successful.
     */

    function BuyFractionNFT() public payable returns (bool) {
        // uint _valOfNFT = msg.value;
        // 1 eth = 1000000000000000000 fraction
        uint256 fractions = msg.value;

        require(fractionsLeft >= fractions, "not enough fractions left");
        fractionsLeft -= fractions;
        TokenInstance.mint(msg.sender, fractions);
        return true;
    }

    function BuyFractionNFTAssembly() public payable returns (bool) {
        // uint _valOfNFT = msg.value;
        // 1 eth = 1000000000000000000 fraction
        // uint256 fractions = msg.value;
        uint256 j;
        require(fractionsLeft >= msg.value, "not enough fractions left");
        assembly {
            sstore(fractionsLeft.slot, 0)
            // j := mload(0)
            j := sub(mload(0), calldataload(0))
        }
        fractionsLeft = j;
        // fractionsLeft -= fractions;
        TokenInstance.mint(msg.sender, msg.value);
        return true;
    }

    function depositFractionsForSell(uint256 _amount) public returns (bool) {
        require(details.setForAuction == true, "not allowed for auction");
        TokenInstance.transferFrom(msg.sender, address(this), _amount);
        forAuctionTokens += _amount;
        depositorsForAuction[msg.sender] += _amount;
        return true;
    }

    function setAuctionProcess() public onlyOwner returns (bool) {
        details.setForAuction = true;
        forAuctionTokens = 0;
        return true;
    }

    function initializeAuction(uint256 _startTime, uint256 _endTime)
        public
        returns (address)
    {
        require(
            forAuctionTokens >= (totalFractions * ((51 * 100) / 100)) / 100,
            "51% of supply should be present in contract"
        );

        AuctionFraction intializeAuctionContract = new AuctionFraction(
            _owner,
            _startTime,
            _endTime,
            details.nftContractDetails,
            details.nftTokenId,
            address(this)
        );

        NFTinstance.transferFrom(
            address(this),
            address(intializeAuctionContract),
            details.nftTokenId
        );
        auctionContract = address(intializeAuctionContract);
        return auctionContract;
    }

    function withdrawEth() public returns (bool) {
        require(fractionsLeft == 0, "still fractions are left");

        (bool sent, ) = tokenOwner.call{
            value: details.amtToSellInEth * (10**18)
        }("");
        require(sent, "Failed to send Ether");
        return true;
    }

    /**
     * @notice Withdraw fractional ownership and the associated NFT.
     * @return True if the withdrawal is successful.
     */

    function endAuctionAndClaimEth(uint256 _ethAmount)
        public
        onlyOwner
        returns (bool)
    {
        details.setForAuction = false;
        ethAmountByAuction = _ethAmount;
        return true;
    }

    function claimETH() public returns (bool) {
        require(details.setForAuction == false, "auction not ended yet");

        if (depositorsForAuction[msg.sender] != 0) {
            uint256 claimEthAmount = ethAmountByAuction *
                (depositorsForAuction[msg.sender] / totalFractions);
            (bool sent, ) = msg.sender.call{value: claimEthAmount}("");
            require(sent, "Failed to send Ether");
            depositorsForAuction[msg.sender] = 0;
            return true;
        } else {
            uint256 getTokenBal = TokenInstance.balanceOf(msg.sender);
            uint256 claimEthAmount = ethAmountByAuction *
                (getTokenBal / totalFractions);
            TokenInstance.transferFrom(msg.sender, address(1), getTokenBal);
            (bool sent, ) = msg.sender.call{value: claimEthAmount}("");
            require(sent, "Failed to send Ether");
            return true;
        }
    }

    function withdrawNFT() public returns (bool) {
        require(details.canTransfer == true, "could not withdraw now");

        require(
            TokenInstance.balanceOf(msg.sender) == details.totalSupply,
            "holding amount should be equal to total supply"
        );
        TokenInstance.transferFrom(
            msg.sender,
            address(this),
            details.totalSupply
        );
        NFTinstance = IMyERC721(details.nftContractDetails);
        NFTinstance.transferFrom(address(this), msg.sender, details.nftTokenId);
        return true;
    }
}
