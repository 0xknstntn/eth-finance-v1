const { expect } = require("chai");
const { ethers } = require("hardhat");

let FactoryAddress;
let GlobalFactory;

let DAIAddress;
let GlobalDAI;

let USDTAddress;
let GlobalUSDT;

let oTokenAddressPool1;
let GlobaloToken;

let PoolAddress
let GlobalPool

let RouterAddress
let GlobalRouter

var d = new Date(); 
datetext = d.getHours()+":"+d.getMinutes()+":"+d.getSeconds();

console.log()
console.log("@dev Konstantin Kljuchnikov");
console.log("@notice Onda Finance");
console.log("@notice exist: Factory, Pool, Router, oToken(lp-token)")
console.log(`@datetime ${datetext}`);
let provider = new ethers.providers.JsonRpcProvider();
describe("Swap Pool Test", function () {
        it("Create DAI", async function(){
                
                [owner, addr1, addr2] = await ethers.getSigners();
                const DAI = await ethers.getContractFactory("ERC20");
                const DAIdeployed = await DAI.deploy("DAI", "DAI");
                await DAIdeployed.mint(addr1.address, 1000000000000);
                USDTAddress = DAIdeployed.address;
                GlobalDAI = DAIdeployed;
        });
        it("Create USDT", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                const USDT = await ethers.getContractFactory("ERC20");
                const USDTdeployed = await USDT.deploy("USDT", "USDT");
                await USDTdeployed.mint(addr1.address, 1000000000000);
                await USDTdeployed.mint(addr2.address, 2);
                DAIAddress = USDTdeployed.address;
                GlobalUSDT = USDTdeployed;
        });
        it("Deploy Factory", async function () {
                const Factory = await ethers.getContractFactory("OndaV1Factory");
                const FactoryDeployed = await Factory.deploy();
                FactoryAddress = FactoryDeployed.address;
                GlobalFactory = FactoryDeployed;
        });
        it("Deploy Router", async function () {
                const Router = await ethers.getContractFactory("OndaV1Router");
                const RouterDeployed = await Router.deploy(FactoryAddress);
                RouterAddress = RouterDeployed.address;
                GlobalRouter = RouterDeployed;
        });
        it("Create New Pool", async function(){
                const { abi } = require('../artifacts/contracts/OndaV1Pool.sol/OndaV1Pool.json');
                const tx = await GlobalFactory.connect(addr1).createPool(DAIAddress, USDTAddress, 40);
                PoolAddress = await GlobalFactory.callStatic.getPoolAddress(DAIAddress, USDTAddress);
                GlobalPool = new ethers.Contract(PoolAddress, abi, provider);
        });
        it("Get oToken from pool", async function(){
                const { abi } = require('../artifacts/contracts/OndaV1Pool.sol/OndaV1Pool.json');
                const oTokenAddressPool1 = await GlobalPool.lp();
                GlobaloToken = new ethers.Contract(oTokenAddressPool1, abi, provider);
        });
        it("Add liquidity", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalRouter.connect(addr1).addLiquidity(DAIAddress, USDTAddress,  10000);
                expect(await GlobalPool.reserve0()).to.equal(10000);
                expect(await GlobalPool.reserve1()).to.equal(10000);
        });
        it("Swap DAI to USDT", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalDAI.mint(addr2.address, 100000);
                await GlobalRouter.connect(addr2).swapPriorityTokenToToken(DAIAddress, USDTAddress, 100);
                expect(await GlobalPool.reserve0()).to.equal(10000-100);
                expect(await GlobalPool.reserve1()).to.equal(10000+104);
        });
        it("Swap USDT to DAI", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalUSDT.mint(addr2.address, 100000);
                await GlobalRouter.connect(addr2).swapTokenToPriorityToken(DAIAddress, USDTAddress, 100);
                expect(await GlobalPool.reserve0()).to.equal(10000+1);
                expect(await GlobalPool.reserve1()).to.equal(10000+4);
        });
        it("Delete liquidity", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalRouter.connect(addr1).deleteLiquidity(DAIAddress, USDTAddress, 9999);
                expect(await GlobalPool.reserve0()).to.equal(0);
                expect(await GlobalPool.reserve1()).to.equal(0);
        });
});
