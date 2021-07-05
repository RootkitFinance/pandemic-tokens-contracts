// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./MicroVirus.sol";

contract MicrobiologyLab {

    address private immutable dev;
    mapping (uint256 => VirusData) public variants;
    uint256 count;

    struct VirusData {
        address virusAddress;      
        address pairedAddress;       
        uint256 burnRate;
        uint256 upPercent;
        uint256 upDelay;
        bool withFee;
        uint256 startPrice;
    }  

    constructor() {
        dev = msg.sender;
    }

    function releaseNewVirus(IERC20 pairedToken, uint256 burnRate, uint256 upPercent, uint256 upDelay, bool withFee, uint256 startPrice) public {        
        MicroVirus newVirus = new MicroVirus(pairedToken, burnRate, upPercent, upDelay, withFee, startPrice, dev, msg.sender);        
        variants[++count] = VirusData({
            virusAddress: address(newVirus),
            pairedAddress: address(pairedToken),
            burnRate: burnRate,
            upPercent: upPercent,
            upDelay: upDelay,
            withFee: withFee,
            startPrice: startPrice
        });

       // VirusData memory doge = variants[count];
       // doge.burnRate;

       // VirusData storage doge = variants[count];
       // doge.burnRate = 69;
    }

}