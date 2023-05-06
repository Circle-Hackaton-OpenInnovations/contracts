// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./PriceConverter.sol";
import "./Managed.sol";

/**
 * @title The CrowdFunding Contract
 * @author 3illBaby
 * @notice This contract makes use of the chainlink oracle nodes to get the latest eth to usd conversion rate
 * TODO: Write a function to get all campaigns
 * TODO: Write a function to list all investors
 */

contract crowdFunding is Managed {
    /**
     * ! Campaign Event
     * @param _title This is the title of the event created
     * @param _shortDescription this is a short description of the event
     */
    event campaignCreated(string _title, string _shortDescription);

    //? This is a library that can be used to covert eth to usd
    using PriceConverter for uint256;
    uint256 public minimumUSD = 10 * 1e18;

    AggregatorV3Interface public priceFeed;
    address private immutable Owner;

    mapping(uint256 => Campaign) allCampaigns;
    mapping(address => mapping(uint256 => Campaign)) Investors;
    uint256 public numberOfCampaigns = 0;

    struct Campaign {
        address owner;
        string title;
        string shortDescription;
        string detailedDescription;
        string category;
        string media;
    }

    /**
     * ? the pricefeed address will be immutable after deployment
     * @param _priceFeedAddress this is the address of the oracle chainlink node used to get the conversion
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
    {
        Campaign memory newCampaign = Campaign({
            owner: msg.sender,
            title: _title,
            shortDescription: _shortDescription,
            detailedDescription: _detailedDescription,
            category: _category,
            media: _mediaURL
        });

        uint256 campaignID = numberOfCampaigns++;
        allCampaigns[campaignID] = newCampaign;
        emit campaignCreated(newCampaign.title, newCampaign.shortDescription);
    }

    /**
     * ? Investors can call this function to donate to the campaing of their choice
     * ! Any investment below $10 will fail
     * ! The conversion ETH to USD price is handled by the PriceConverter library
     * @param _campaignId This is the ID of the Campaign that the donation is intended for
     */
    function invest(uint256 _campaignId) public payable {
        if (msg.value.getConversionRate(priceFeed) < minimumUSD) {
            revert insufficientFunds();
        }

        uint256 amountDonated = msg.value;

        Campaign memory campaign = allCampaigns[_campaignId];
        Investors[msg.sender][amountDonated] = campaign;

        (bool sent, ) = payable(campaign.owner).call{value: amountDonated}("");

        if (!sent) {
            revert transactionFailed();
        }
    }
}
