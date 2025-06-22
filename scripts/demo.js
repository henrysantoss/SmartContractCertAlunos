const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: true });

function clearScreen() {
    process.stdout.write("\x1Bc");
}

function pause() {
    prompt("\nPressione qualquer tecla para continuar...");
}

async function main() {
    // Pega as contas disponíveis
    const signers = await hre.ethers.getSigners();
    const admin = signers[0];
    let alunos = signers.slice(1, 6); // 5 alunos para exemplo

    // Lista de hashes disponíveis para emissão de certificados
    let hashesDisponiveis = [
        "hash123",
        "hash456",
        "hash789",
        "hashabc",
        "hashdef",
        "hashteste"
    ];

    // Deploy dos contratos
    const ContratoCertificados = await hre.ethers.getContractFactory("ContratoCertificados");
    const contratoCertificados = await ContratoCertificados.deploy();
    await contratoCertificados.waitForDeployment();

    const TokenCertiToken = await hre.ethers.getContractFactory("TokenCertiToken");
    const certiToken = await TokenCertiToken.deploy();
    await certiToken.waitForDeployment();

    clearScreen();
    console.log("\n=== Contratos implantados ===");
    console.log("ContratoCertificados:", await contratoCertificados.getAddress());
    console.log("CertiToken:", await certiToken.getAddress());
    pause();

    // Função utilitária para escolher um aluno disponível
    function escolherAlunoDisponivel() {
        if (alunos.length === 0) {
            console.log("Não há mais alunos disponíveis para emissão!");
            pause();
            return null;
        }
        console.log("\nAlunos disponíveis:");
        alunos.forEach((a, i) => {
            console.log(`${i + 1}. ${a.address}`);
        });
        const idx = parseInt(prompt("Escolha o número do aluno: ")) - 1;
        if (idx < 0 || idx >= alunos.length) {
            console.log("Aluno inválido!");
            return null;
        }
        return { aluno: alunos[idx], idx };
    }

    // Função utilitária para escolher qualquer aluno (para consulta, saldo, etc)
    function escolherAlunoTodos() {
        const todos = signers.slice(1, 6);
        console.log("\nAlunos:");
        todos.forEach((a, i) => {
            console.log(`${i + 1}. ${a.address}`);
        });
        const idx = parseInt(prompt("Escolha o número do aluno: ")) - 1;
        if (idx < 0 || idx >= todos.length) {
            console.log("Aluno inválido!");
            return null;
        }
        return todos[idx];
    }

    // Menu interativo
    while (true) {
        clearScreen();
        console.log("\n=== MENU DEMONSTRAÇÃO ===");
        console.log("1. Emitir certificado para aluno");
        console.log("2. Consultar certificado por ID");
        console.log("3. Listar todos os certificados emitidos");
        console.log("4. Enviar tokens CTK para aluno");
        console.log("5. Ver saldo de tokens de um aluno");
        console.log("0. Sair");
        const op = prompt("Escolha uma opção: ");

        if (op === "1") {
            clearScreen();
            const escolha = escolherAlunoDisponivel();
            if (!escolha) continue;
            const { aluno, idx } = escolha;
            const nomeAluno = prompt("Nome do aluno: ");
            const nomeCurso = prompt("Nome do curso/evento: ");
            const hash = prompt("Hash do certificado (ex: hash123): ");
            const descricao = prompt("Descrição do curso: ");
            const carga = prompt("Carga horária: ");
            const instituicao = prompt("Instituição emissora: ");
            while (true) {
                try {
                    const tx = await contratoCertificados.emitirCertificado(
                        aluno.address,
                        nomeAluno,
                        nomeCurso,
                        hash,
                        descricao,
                        carga,
                        instituicao
                    );
                    await tx.wait();
                    // Remove o hash usado da lista
                    hashesDisponiveis = hashesDisponiveis.filter(h => h !== hash);
                    // Remove o aluno da lista de disponíveis para emissão
                    alunos.splice(idx, 1);
                    const total = await contratoCertificados.obterTotalCertificados();
                    console.log("Certificado emitido! ID:", total.toString());
                    pause();
                    break;
                } catch (e) {
                    if (e.message && e.message.includes('read ECONNRESET')) {
                        console.log("Erro de conexão, tentando novamente...");
                        continue;
                    } else {
                        console.log("Erro ao emitir:", e.message);
                        pause();
                        break;
                    }
                }
            }
        }

        else if (op === "2") {
            clearScreen();
            const id = prompt("ID do certificado: ");
            while (true) {
                try {
                    const cert = await contratoCertificados.obterCertificado(id);
                    console.log("=== Certificado ===");
                    console.log("ID:", cert.id.toString());
                    console.log("Aluno:", cert.nomeAluno);
                    console.log("Curso:", cert.nomeCurso);
                    console.log("Data emissão:", new Date(Number(cert.dataEmissao) * 1000).toLocaleString());
                    console.log("Válido:", cert.valido);
                    console.log("Hash:", cert.hashCertificado);
                    console.log("Instituição:", cert.instituicaoEmissora);
                    pause();
                    break;
                } catch (e) {
                    if (e.message && e.message.includes('read ECONNRESET')) {
                        console.log("Erro de conexão, tentando novamente...");
                        continue;
                    } else {
                        console.log("Erro ao consultar:", e.message);
                        pause();
                        break;
                    }
                }
            }
        }

        else if (op === "3") {
            clearScreen();
            while (true) {
                try {
                    const total = await contratoCertificados.obterTotalCertificados();
                    if (total == 0) {
                        console.log("Nenhum certificado emitido ainda.");
                    } else {
                        for (let i = 1; i <= total; i++) {
                            const cert = await contratoCertificados.obterCertificado(i);
                            console.log(`ID: ${cert.id} | Aluno: ${cert.nomeAluno} | Curso: ${cert.nomeCurso} | Data: ${new Date(Number(cert.dataEmissao) * 1000).toLocaleString()} | Válido: ${cert.valido}`);
                        }
                    }
                    pause();
                    break;
                } catch (e) {
                    if (e.message && e.message.includes('read ECONNRESET')) {
                        console.log("Erro de conexão, tentando novamente...");
                        continue;
                    } else {
                        console.log("Erro ao listar:", e.message);
                        pause();
                        break;
                    }
                }
            }
        }

        else if (op === "4") {
            clearScreen();
            const aluno = escolherAlunoTodos();
            if (!aluno) continue;
            const valor = prompt("Quantidade de tokens CTK: ");
            while (true) {
                try {
                    const tx = await certiToken.transfer(aluno.address, valor);
                    await tx.wait();
                    console.log("Tokens enviados!");
                    pause();
                    break;
                } catch (e) {
                    if (e.message && e.message.includes('read ECONNRESET')) {
                        console.log("Erro de conexão, tentando novamente...");
                        continue;
                    } else {
                        console.log("Erro ao enviar tokens:", e.message);
                        pause();
                        break;
                    }
                }
            }
        }

        else if (op === "5") {
            clearScreen();
            const aluno = escolherAlunoTodos();
            if (!aluno) continue;
            while (true) {
                try {
                    const saldo = await certiToken.balanceOf(aluno.address);
                    console.log("Saldo de tokens CTK:", saldo.toString());
                    pause();
                    break;
                } catch (e) {
                    if (e.message && e.message.includes('read ECONNRESET')) {
                        console.log("Erro de conexão, tentando novamente...");
                        continue;
                    } else {
                        console.log("Erro ao consultar saldo:", e.message);
                        pause();
                        break;
                    }
                }
            }
        }

        else if (op === "0") {
            clearScreen();
            break;
        }

        else {
            console.log("Opção inválida!");
            pause();
        }
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
