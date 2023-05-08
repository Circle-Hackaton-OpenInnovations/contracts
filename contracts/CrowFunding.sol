// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./PriceConverter.sol";
import "./Managed.sol";

/**
 * @title The CrowdFunding Contract
 * @author 3illBaby
 * @notice This contract makes use of the chainlink oracle nodes to get the latest eth to usd conversion rate
 */

contract crowdFunding is Managed {
    /**
     * ! Campaign Event
     * @param _title This is the title of the event created
     * @param _shortDescription this is a short description of the event
     */
    event campaignCreated(string _title, string _shortDescription);
    event campaignFunded(
        address indexed _investor,
        uint256 indexed _campaignId,
        uint256 indexed _amountInvested
    );

    //? This is a library that can be used to covert eth to usd
    using PriceConverter for uint256;
    uint256 public minimumUSD = 20 * 1e18;

    AggregatorV3Interface public priceFeed;
    address private immutable Owner;

    mapping(uint32 => Campaign) allCampaigns;
    uint32[] public campaignKeys;
    mapping(address => mapping(uint256 => uint256)) Investors;
    uint256 public numberOfCampaigns = 0;

    struct Campaign {
        address owner;
        string title;
        string shortDescription;
        string detailedDescription;
        string category;
        string media;
        address[] donators;
        uint256[] donations;
    }

    /**
     * ? the pricefeed address will be immutable after deployment
     * @param _priceFeedAddress this is the address of the oracle chainlink node used to get the conversion
     * ? Goerli priceFeed Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * ? Mumbai priceFeed Address 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */
    constructor(address _priceFeedAddress) {
        Owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
     * ! This function Creates a Campaign
     * @param _title The title of the campaign
     * @param _shortDescription A short description of the campaign
     * @param _detailedDescription A detailed description of the campaign
     * @param _category The Campaign category
     * @param _mediaURL The image or video URL
     */
    function createCampaign(
        string memory _title,
        string memory _shortDescription,
        string memory _detailedDescription,
        string memory _category,
        string memory _mediaURL
    )
        public
        blankCompliance(
            _title,
            _shortDescription,
            _detailedDescription,
            _category,
            _mediaURL
        )
        returns (uint256)
    {
        uint256 key = campaignKeys.length;
        allCampaigns[uint32(key)] = Campaign({
            owner: msg.sender,
            title: _title,
            shortDescription: _shortDescription,
            detailedDescription: _detailedDescription,
            category: _category,
            media: _mediaURL,
            donators: new address[](0),
            donations: new uint256[](0)
        });
        campaignKeys.push(uint32(key));
        numberOfCampaigns++;

        emit campaignCreated(_title, _shortDescription);

        return key;
    }

    /**
     * ? Investors can call this function to donate to the campaing of their choice
     * ! Any investment below $20 will fail
     * ! The conversion ETH to USD price is handled by the PriceConverter library
     * @param _campaignId This is the ID of the Campaign that the donation is intended for
     */
    function invest(uint32 _campaignId) public payable {
        require(_campaignId <= campaignKeys.length, "Invalid Campaign ID");

        uint256 amountInvested = msg.value;
        uint256 usdValue = amountInvested.getConversionRate(priceFeed);
        require(usdValue >= minimumUSD, "Investment below $20 not allowed");
        Campaign storage campaign = allCampaigns[_campaignId];
        uint256 gasBuffer = ((amountInvested * 2) / 100) +
            (amountInvested / 20);

        uint256 campaignAmount = amountInvested - gasBuffer;

        (bool sent, ) = payable(campaign.owner).call{value: campaignAmount}("");

        if (!sent) {
            revert transactionFailed();
        }
        uint256 investorAmount = amountInvested - campaignAmount - gasBuffer;
        Investors[msg.sender][_campaignId] += investorAmount;
        campaign.donators.push(msg.sender);
        campaign.donations.push(investorAmount);

        emit campaignFunded(msg.sender, _campaignId, investorAmount);
    }

    /**
     *
     * @param _id this is the id of the campaign you want to get the donators
     * @return This returns an array of all the donators of that campaign
     * @return This returns an array of all the amount donated
     */
    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (
            allCampaigns[uint32(_id)].donators,
            allCampaigns[uint32(_id)].donations
        );
    }

    //? This function gets all campaigns
    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory campaigns = new Campaign[](campaignKeys.length);
        for (uint256 i = 0; i < campaignKeys.length; i++) {
            campaigns[i] = allCampaigns[campaignKeys[i]];
        }

        return campaigns;
    }

    function withdraw() public payable {
        require(msg.sender == Owner, "only owner can call this function");
        (bool sent, ) = payable(Owner).call{value: address(this).balance}("");
        require(sent, "This transaction failed");
    }

    receive() external payable {
        invest(0);
    }

    fallback() external payable {
        invest(0);
    }
}
