const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying with account:", deployer.address);

  const ContratoCertificados = await hre.ethers.getContractFactory("ContratoCertificados");
  const contrato = await ContratoCertificados.deploy();

  await contrato.waitForDeployment();

  console.log("ContratoCertificados deployed to:", await contrato.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
