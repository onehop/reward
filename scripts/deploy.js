async function main() {
  const Reward = await ethers.getContractFactory("HOPReward");
  const hopAddress = "0x984811e6f2695192add6f88615dF637bf52a5Cae"
  const busdAddress = "0xe9e7cea3dedca5984780bafc599bd69add087d56"
  const routerAddress = "0x10ed43c718714eb63d5aa57b78b54704e256024e" 
  const donationAddress = "0x58538AB4B440d039F96085abf2E3D87870890833" 
  const reward = await Reward.deploy(hopAddress, busdAddress, routerAddress, donationAddress);
  await reward.deployed();
  console.log(reward.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
