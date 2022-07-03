const hre = require('hardhat')

// Define the NFT
const _token0 = '0x517ea0Aa2840B7288477e4a6818929dB6bd88372'
const _token1 = '0x5a9D6D65c9F0434E002663FcAf6115a7F3DEAaa4'
const _lp = '0xb2b2E089bA65FC25366C514767Ec30E162bFdF1c'


async function main() {
  /*await hre.run('verify:verify', {
    address: '0x155A504e9b6D792dD27eC9270aDd158f1A9587Ed',
    constructorArguments: [
      _token0,
      _token1,
      _lp
    ],
  })
  console.log('verifed')
  await hre.run('verify:verify', {
    address: '0xfaD5158F69C7DBA126cdb1C0Ec42c9C42888CeB8',
    constructorArguments: [
      "AsuokiToken1",
      "AST1"
    ],
  })
  console.log('verifed')*/
  await hre.run('verify:verify', {
    address: '0x517ea0Aa2840B7288477e4a6818929dB6bd88372',
    constructorArguments: [],
  })
  console.log('verifed')
  await hre.run('verify:verify', {
    address: '0x5a9D6D65c9F0434E002663FcAf6115a7F3DEAaa4',
    constructorArguments: [
      "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", 
      "0x13512979ADE267AB5100878E2e0f485B568328a4", 
      "0x517ea0Aa2840B7288477e4a6818929dB6bd88372", 
      40
    ],
  })
  console.log('verifed')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })