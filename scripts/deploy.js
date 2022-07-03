async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  const FACTORY = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
  // USDC
  const TOKEN_0 = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
  const DECIMALS_0 = 18n
  // WETH
  const TOKEN_1 = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063"
  const DECIMALS_1 = 18n
  const FEE = 3000
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const UniswapV3Twap = await ethers.getContractFactory("UniswapV3Twap")
  const twap = await UniswapV3Twap.deploy(FACTORY, TOKEN_0, TOKEN_1, FEE)
  await twap.deployed()
  console.log("LP deployed at:", twap.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
  console.error(error);
  process.exit(1);
  });
