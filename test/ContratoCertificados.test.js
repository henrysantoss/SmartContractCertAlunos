const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ContratoCertificados", function () {
  let contrato, owner, admin, aluno, outro;

  beforeEach(async function () {
    [owner, admin, aluno, outro] = await ethers.getSigners();
    const ContratoCertificados = await ethers.getContractFactory("ContratoCertificados");
    contrato = await ContratoCertificados.deploy();
    await contrato.waitForDeployment();
  });

  it("Deve permitir ao owner adicionar um administrador", async function () {
    await contrato.adicionarAdministrador(admin.address);
    expect(await contrato.verificarAdministrador(admin.address)).to.be.true;
  });

  it("Deve emitir um certificado e permitir consulta", async function () {
    await contrato.adicionarAdministrador(admin.address);
    await contrato.connect(admin).emitirCertificado(
      aluno.address,
      "Aluno Teste",
      "Curso Teste",
      "hash123",
      "Descrição do curso",
      40,
      "Instituição"
    );
    const total = await contrato.obterTotalCertificados();
    expect(total).to.equal(1);

    const cert = await contrato.obterCertificado(1);
    expect(cert.nomeAluno).to.equal("Aluno Teste");
    expect(cert.valido).to.be.true;
  });

  it("Deve revogar um certificado", async function () {
    await contrato.adicionarAdministrador(admin.address);
    await contrato.connect(admin).emitirCertificado(
      aluno.address,
      "Aluno Teste",
      "Curso Teste",
      "hash123",
      "Descrição do curso",
      40,
      "Instituição"
    );
    await contrato.connect(admin).revogarCertificado(1);
    const cert = await contrato.obterCertificado(1);
    expect(cert.valido).to.be.false;
  });

  it("Deve consultar certificados por aluno", async function () {
    await contrato.adicionarAdministrador(admin.address);
    await contrato.connect(admin).emitirCertificado(
      aluno.address,
      "Aluno Teste",
      "Curso Teste",
      "hash123",
      "Descrição do curso",
      40,
      "Instituição"
    );
    const ids = await contrato.obterCertificadosDoAluno(aluno.address);
    expect(ids.length).to.equal(1);
    expect(ids[0]).to.equal(1);
  });

  it("Deve pausar e despausar o contrato", async function () {
    await contrato.pausarContrato();
    await expect(
      contrato.emitirCertificado(
        aluno.address,
        "Aluno Teste",
        "Curso Teste",
        "hash123",
        "Descrição do curso",
        40,
        "Instituição"
      )
    ).to.be.reverted;
    await contrato.despausarContrato();
    await contrato.emitirCertificado(
      aluno.address,
      "Aluno Teste",
      "Curso Teste",
      "hash1234",
      "Descrição do curso",
      40,
      "Instituição"
    );
    expect(await contrato.obterTotalCertificados()).to.equal(1);
  });
});
