# Sistema de Certificados Digitais e Recompensas (CertiToken)

Este projeto é um sistema blockchain para emissão de certificados digitais educacionais e recompensas em tokens ERC20 (CertiToken - CTK). Ele permite que um administrador emita certificados para alunos, armazene e consulte informações dos certificados, e envie tokens de recompensa para os alunos.

## Pré-requisitos
- [Node.js](https://nodejs.org/) (recomendado v18 ou superior)
- [npm](https://www.npmjs.com/)
- [Hardhat](https://hardhat.org/)

## Instalação

1. **Clone o repositório:**
   ```sh
   git clone <url-do-repositorio>
   cd <nome-da-pasta>
   ```
2. **Instale as dependências:**
   ```sh
   npm install
   ```

## Compilando os contratos
```sh
npx hardhat compile
```

## Rodando a blockchain local
Em um terminal separado, execute:
```sh
npx hardhat node --port 9545
```

## Executando o menu interativo
Abra outro terminal e execute:
```sh
npx hardhat run scripts/demo.js --network localhost
```

## Funcionalidades do menu interativo

1. **Emitir certificado para aluno**
   - Escolha um aluno disponível.
   - Preencha os dados do certificado.
   - O certificado é emitido e armazenado no blockchain.
2. **Consultar certificado por ID**
   - Informe o ID do certificado para ver os dados completos.
3. **Listar todos os certificados emitidos**
   - Mostra todos os certificados já emitidos, com dados resumidos.
4. **Enviar tokens CTK para aluno**
   - Escolha um aluno e envie uma quantidade de tokens CertiToken (CTK) como recompensa.
5. **Ver saldo de tokens de um aluno**
   - Escolha um aluno para ver o saldo de tokens CTK.
0. **Sair**

## Sobre os contratos
- **ContratoCertificados:** Permite ao administrador emitir, consultar e listar certificados digitais para alunos.
- **TokenCertiToken (ERC20):** Token de recompensa chamado CertiToken (CTK), que pode ser enviado para alunos como premiação.

## Observações
- Use sempre a blockchain local (`npx hardhat node --port 9545`) para garantir rapidez e controle durante os testes.
- O menu mostra os endereços dos alunos para facilitar a escolha.
- Os dados são persistidos enquanto o node local estiver rodando.