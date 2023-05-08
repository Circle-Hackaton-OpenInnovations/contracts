// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
error insufficientFunds();
error transactionFailed();

contract Managed {
    modifier blankCompliance(
        string memory _title,
        string memory _shortDescription,
        string memory _detailedDescription,
        string memory _category,
        string memory _mediaURL
    ) {
        require(
            bytes(_title).length > 0 &&
                bytes(_shortDescription).length > 0 &&
                bytes(_detailedDescription).length > 0 &&
                bytes(_category).length > 0 &&
                bytes(_mediaURL).length > 0,
            "can't be left blank"
        );
        _;
    }
}
