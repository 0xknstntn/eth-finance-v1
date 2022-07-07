/*
        ================= Use ganache for testing =================
*/
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

let aTokenAddress
let GlobalaToken

let SwapPoolAddress
let GlobalSwapPool

let RouterAddress
let GlobalRouter

let SwapPoolFactoryAddress
let GlobalSwapPoolFactory

let LendingPoolFactoryAddress
let GlobalLendingPoolFactory

let ProviderAddress
let GlobalProvider

let LendPoolAddress
let GlobalLendPool

var d = new Date(); 
datetext = d.getHours()+":"+d.getMinutes()+":"+d.getSeconds();

console.log()
console.log("@dev Konstantin Kljuchnikov");
console.log("@notice Onda Finance");
console.log(`@datetime ${datetext}`);
let provider = new ethers.providers.JsonRpcProvider();
describe("Swap Pool Test", function () {
        it("Create DAI", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                const DAI = await ethers.getContractFactory("ERC20");
                const DAIdeployed = await DAI.deploy("DAI", "DAI");
                await DAIdeployed.mint(addr1.address, 1000000000000);
                DAIAddress = DAIdeployed.address;
                GlobalDAI = DAIdeployed;
        });
        it("Create USDT", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                const USDT = await ethers.getContractFactory("ERC20");
                const USDTdeployed = await USDT.deploy("USDT", "USDT");
                await USDTdeployed.mint(addr1.address, 1000000000000);
                USDTAddress = USDTdeployed.address;
                GlobalUSDT = USDTdeployed;
        });
        it("Deploy SwapPoolFactory", async function () {
                const SwapPoolFactory = await ethers.getContractFactory("OndaV1SwapPoolFactory");
                const SwapPoolFactoryDeployed = await SwapPoolFactory.deploy();
                SwapPoolFactoryAddress = SwapPoolFactoryDeployed.address;
                GlobalSwapPoolFactory = SwapPoolFactoryDeployed;
        });
        it("Deploy LendingPoolFactory", async function () {
                const LendingPoolFactory = await ethers.getContractFactory("OndaV1LendingPoolFactory");
                const LendingPoolFactoryDeployed = await LendingPoolFactory.deploy();
                LendingPoolFactoryAddress = LendingPoolFactoryDeployed.address;
                GlobalLendingPoolFactory = LendingPoolFactoryDeployed;
        });
        it("Deploy Address provider", async function () {
                const provider = await ethers.getContractFactory("OndaV1AddressProvider");
                const ProviderDeployed = await provider.deploy(LendingPoolFactoryAddress, SwapPoolFactoryAddress);
                ProviderAddress = ProviderDeployed.address;
                GlobalProvider = ProviderDeployed;
        });
        it("Deploy Router", async function () {
                const Router = await ethers.getContractFactory("OndaV1Router");
                const RouterDeployed = await Router.deploy(ProviderAddress);
                RouterAddress = RouterDeployed.address;
                GlobalRouter = RouterDeployed;
        });
        it("Create New Lending Pool With Zero Router", async function() {
                await expect(GlobalLendingPoolFactory.connect(addr1).createLendingPool(DAIAddress)).to.be.reverted;
        });
        it("Set new Router in LendingPoolFactory", async function () {
                await GlobalLendingPoolFactory.setRouter(RouterAddress);
                expect(await GlobalLendingPoolFactory.router()).to.equal(RouterAddress);
        });
        it("Create New Swap Pool", async function(){
                const { abi } = require('../artifacts/contracts/pool/OndaV1SwapPool.sol/OndaV1SwapPool.json');
                const tx = await GlobalSwapPoolFactory.connect(addr1).createSwapPool(DAIAddress, USDTAddress, 40);
                SwapPoolAddress = await GlobalSwapPoolFactory.callStatic.getSwapPoolAddress(DAIAddress, USDTAddress);
                GlobalSwapPool = new ethers.Contract(SwapPoolAddress, abi, provider);
        });
        it("Create New Lending Pool With none-zero Router", async function() {
                const { abi } = require('../artifacts/contracts/pool/OndaV1LendingPool.sol/OndaV1LendingPool.json');
                await GlobalLendingPoolFactory.connect(owner).createLendingPool(DAIAddress);
        });
        it("Get global lending pool", async function(){
                const { abi } = require('../artifacts/contracts/pool/OndaV1LendingPool.sol/OndaV1LendingPool.json');
                LendPoolAddress = await GlobalLendingPoolFactory.callStatic.getLendingPoolAddress(DAIAddress);
                GlobalLendPool = new ethers.Contract(LendPoolAddress, abi, provider);
        });
        it("Get aToken from lending pool", async function(){
                const { abi } = require('../artifacts/contracts/token/aToken.sol/aToken.json');
                aTokenAddress = await GlobalLendPool.aToken();
                GlobalaToken = new ethers.Contract(aTokenAddress, abi, provider);
        });
        it("Get oToken from swap pool", async function(){
                const { abi } = require('../artifacts/contracts/token/oToken.sol/oToken.json');
                const oTokenAddressPool1 = await GlobalSwapPool.lp();
                GlobaloToken = new ethers.Contract(oTokenAddressPool1, abi, provider);
        });
        it("Check getSwapPoolAddress()", async function(){
                expect(await GlobalSwapPoolFactory.callStatic.getSwapPoolAddress(DAIAddress, USDTAddress)).to.equal(SwapPoolAddress);
                expect(await GlobalSwapPoolFactory.callStatic.getSwapPoolAddress(USDTAddress, DAIAddress)).to.equal(SwapPoolAddress);
        });
        it("Add liquidity", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                expect(await GlobalSwapPool.totalSupply()).to.equal(0);
                expect((await GlobalDAI.balanceOf(addr1.address)) > 10000).to.be.true;
                expect((await GlobalUSDT.balanceOf(addr1.address)) > 10000).to.be.true;                
                await GlobalRouter.connect(addr1).addLiquidity(DAIAddress, USDTAddress, 10000);
                expect(await GlobalSwapPool.reserve0()).to.equal(10000);
                expect(await GlobalSwapPool.reserve1()).to.equal(10000);
                expect(await GlobalSwapPool.price0()).to.equal(1000000);
                expect(await GlobalSwapPool.price1()).to.equal(1000000);
        });
        it("Swap DAI to USDT", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalDAI.mint(addr2.address, 100000);
                expect((await GlobalDAI.balanceOf(addr2.address)) > 100).to.be.true;
                await GlobalRouter.connect(addr2).swapPriorityTokenToToken(DAIAddress, USDTAddress, 100);
                expect(await GlobalSwapPool.reserve0()).to.equal(10000+104);
                expect(await GlobalSwapPool.reserve1()).to.equal(10000-100);
        });
        it("Swap USDT to DAI", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalUSDT.mint(addr2.address, 100000);
                expect((await GlobalUSDT.balanceOf(addr2.address)) > 100).to.be.true;
                await GlobalRouter.connect(addr2).swapTokenToPriorityToken(DAIAddress, USDTAddress, 100);
                expect(await GlobalSwapPool.reserve0()).to.equal(10000+4);
                expect(await GlobalSwapPool.reserve1()).to.equal(10000+6);
        });
        it("Delete liquidity", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalRouter.connect(addr1).deleteLiquidity(DAIAddress, USDTAddress, 9999);
                expect(await GlobalSwapPool.reserve0()).to.equal(0);
                expect(await GlobalSwapPool.reserve1()).to.equal(0);
        });
        it("Add new lend", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalRouter.connect(addr1).addLend(DAIAddress, aTokenAddress, 1000);
                expect(await GlobalaToken.balanceOf(addr1.address)).to.equal(1000);
                expect(await GlobalaToken.totalSupply()).to.equal(1000);
                expect(await GlobalLendPool.reserve0()).to.equal(1000);
                expect(await GlobalDAI.balanceOf(addr1.address)).to.equal(999999999004);
        });
        it("New borrow", async function(){
                [owner, addr1, addr2] = await ethers.getSigners();
                expect(await GlobalaToken.balanceOf(addr1.address)).to.equal(1000);
                var balancebBefore = await GlobalDAI.balanceOf(addr2.address);
                await GlobalRouter.connect(addr2).newBorrow(DAIAddress, aTokenAddress, 800, { value: ethers.utils.parseEther("1") });
                expect(await GlobalLendPool.reserve0()).to.equal(200);
                expect(await GlobalDAI.balanceOf(addr2.address)).to.equal(parseInt(balancebBefore) + 800);
        });
        it("Delete borrow", async function(){
                await ethers.provider.send("evm_increaseTime", [1 * 24 * 60 * 60]); // 5 days
                [owner, addr1, addr2] = await ethers.getSigners();
                await GlobalRouter.connect(addr2).deleteBorrow(DAIAddress, aTokenAddress, 802);
                expect(await GlobalLendPool.reserve0()).to.equal(1002);
                expect(await GlobalaToken.balanceOf(addr2.address)).to.equal(0);
        });
        it("Delete lend", async function(){
                await ethers.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]); // 5 days
                [owner, addr1, addr2] = await ethers.getSigners();
                const oldBalance = await GlobalaToken.balanceOf(addr1.address);
                await GlobalRouter.connect(addr1).deleteLend(DAIAddress, aTokenAddress, 1000);
                expect(await GlobalaToken.balanceOf(addr1.address)).to.equal(0);
                expect(await GlobalaToken.totalSupply()).to.equal(0);
                expect(await GlobalLendPool.reserve0()).to.equal(1);
        });
});
