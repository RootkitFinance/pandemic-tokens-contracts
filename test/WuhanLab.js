const { expect } = require("chai");
const { constants, utils, BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const WETH9Json = require('../contracts/json/WETH9.json');
const UniswapV3FactoryJson = require('../contracts/json/UniswapV3Factory.json');
const NonfungiblePositionManagerJson = require('../contracts/json/NonfungiblePositionManager.json');
const QuoterJson = require('../contracts/json/Quoter.json');

describe("WuhanLab", function() {
    let owner, rootKit, pairedToken, wuhanLab, positionManager, quoter, tokenDescriptor;

    beforeEach(async function() {
        [owner, tokenDescriptor] = await ethers.getSigners();
        const rootKitFactory = await ethers.getContractFactory("ERC20Test");
        rootKit = await rootKitFactory.connect(owner).deploy();
        const pairedTokenFactory = await ethers.getContractFactory("ERC20Test");
        pairedToken = await pairedTokenFactory.connect(owner).deploy();
        const weth = await new ethers.ContractFactory(WETH9Json.abi, WETH9Json.bytecode, owner).deploy();
        const factory = await new ethers.ContractFactory(UniswapV3FactoryJson.abi, UniswapV3FactoryJson.bytecode, owner).deploy();
        positionManager = await new ethers.ContractFactory(NonfungiblePositionManagerJson.abi, NonfungiblePositionManagerJson.bytecode, owner).deploy(factory.address, weth.address, tokenDescriptor.address);
        quoter = await new ethers.ContractFactory(QuoterJson.abi, QuoterJson.bytecode, owner).deploy(factory.address, weth.address);
        const wuhanLabFactory = await ethers.getContractFactory("WuhanLab");
        wuhanLab = await wuhanLabFactory.connect(owner).deploy(positionManager.address, factory.address, quoter.address, rootKit.address);
    })

    it("initializes as expected", async function() {
        expect(await wuhanLab.fee()).to.equal(10000);
        expect(await wuhanLab.tickSpacing()).to.equal(200);
    })

    it("lab leaks", async function() {
        await wuhanLab.labLeak(pairedToken.address, 200);
    })
        
})