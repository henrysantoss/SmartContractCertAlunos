// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TokenCertiToken
 * @dev Token ERC20 para recompensas educacionais
 * @author Equipe de Desenvolvimento
 */
contract TokenCertiToken is ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard {
    
    // Estrutura para armazenar informações de recompensa
    struct Recompensa {
        uint256 quantidade;
        string motivo;
        uint256 dataEnvio;
        address remetente;
    }
    
    // Mapeamentos para controle de recompensas
    mapping(address => Recompensa[]) public historicoRecompensas;
    mapping(address => uint256) public totalRecompensasRecebidas;
    mapping(address => bool) public administradoresRecompensas;
    
    // Eventos para acompanhamento
    event RecompensaEnviada(
        address indexed aluno,
        uint256 quantidade,
        string motivo,
        uint256 dataEnvio
    );
    
    event RecompensasEmLote(
        address[] alunos,
        uint256[] quantidades,
        string motivo,
        uint256 dataEnvio
    );
    
    event TokensQueimados(
        address indexed de,
        uint256 quantidade,
        string motivo,
        uint256 dataQueima
    );
    
    event AdministradorRecompensasAdicionado(address indexed administrador);
    event AdministradorRecompensasRemovido(address indexed administrador);
    
    // Modificadores
    modifier apenasAdministradorRecompensas() {
        require(
            msg.sender == owner() || administradoresRecompensas[msg.sender],
            "Apenas administradores de recompensas podem executar esta acao"
        );
        _;
    }
    
    modifier quantidadeValida(uint256 _quantidade) {
        require(_quantidade > 0, "Quantidade deve ser maior que zero");
        _;
    }
    
    constructor() ERC20("CertiToken", "CTK") Ownable(msg.sender) {
        // Mint inicial de 1.000.000 tokens para o administrador
        uint256 quantidadeInicial = 1000000 * 10 ** decimals();
        _mint(msg.sender, quantidadeInicial);
        administradoresRecompensas[msg.sender] = true;
    }
    
    /**
     * @dev Envia tokens como recompensa para um aluno
     * @param _aluno Endereço do aluno
     * @param _quantidade Quantidade de tokens
     * @param _motivo Motivo da recompensa
     */
    function enviarRecompensa(
        address _aluno,
        uint256 _quantidade,
        string memory _motivo
    ) public apenasAdministradorRecompensas quantidadeValida(_quantidade) whenNotPaused nonReentrant {
        require(_aluno != address(0), "Endereco do aluno invalido");
        require(balanceOf(msg.sender) >= _quantidade, "Saldo insuficiente");
        require(bytes(_motivo).length > 0, "Motivo nao pode estar vazio");
        
        // Transfere os tokens
        _transfer(msg.sender, _aluno, _quantidade);
        
        // Registra a recompensa no histórico
        Recompensa memory novaRecompensa = Recompensa({
            quantidade: _quantidade,
            motivo: _motivo,
            dataEnvio: block.timestamp,
            remetente: msg.sender
        });
        
        historicoRecompensas[_aluno].push(novaRecompensa);
        totalRecompensasRecebidas[_aluno] += _quantidade;
        
        emit RecompensaEnviada(_aluno, _quantidade, _motivo, block.timestamp);
    }
    
    /**
     * @dev Envia recompensas em lote para múltiplos alunos
     * @param _alunos Array de endereços dos alunos
     * @param _quantidades Array de quantidades de tokens
     * @param _motivo Motivo da recompensa
     */
    function enviarRecompensasEmLote(
        address[] memory _alunos,
        uint256[] memory _quantidades,
        string memory _motivo
    ) public apenasAdministradorRecompensas whenNotPaused nonReentrant {
        require(_alunos.length == _quantidades.length, "Arrays devem ter o mesmo tamanho");
        require(_alunos.length > 0, "Arrays nao podem estar vazios");
        require(bytes(_motivo).length > 0, "Motivo nao pode estar vazio");
        
        uint256 quantidadeTotal = 0;
        for (uint256 i = 0; i < _quantidades.length; i++) {
            quantidadeTotal += _quantidades[i];
        }
        
        require(balanceOf(msg.sender) >= quantidadeTotal, "Saldo insuficiente");
        
        for (uint256 i = 0; i < _alunos.length; i++) {
            require(_alunos[i] != address(0), "Endereco do aluno invalido");
            require(_quantidades[i] > 0, "Quantidade deve ser maior que zero");
            
            // Transfere os tokens
            _transfer(msg.sender, _alunos[i], _quantidades[i]);
            
            // Registra a recompensa no histórico
            Recompensa memory novaRecompensa = Recompensa({
                quantidade: _quantidades[i],
                motivo: _motivo,
                dataEnvio: block.timestamp,
                remetente: msg.sender
            });
            
            historicoRecompensas[_alunos[i]].push(novaRecompensa);
            totalRecompensasRecebidas[_alunos[i]] += _quantidades[i];
        }
        
        emit RecompensasEmLote(_alunos, _quantidades, _motivo, block.timestamp);
    }
    
    /**
     * @dev Queima tokens de um endereço específico
     * @param _de Endereço de onde queimar os tokens
     * @param _quantidade Quantidade de tokens a queimar
     * @param _motivo Motivo da queima
     */
    function queimarDe(
        address _de,
        uint256 _quantidade,
        string memory _motivo
    ) public apenasAdministradorRecompensas quantidadeValida(_quantidade) {
        require(_de != address(0), "Endereco invalido");
        require(balanceOf(_de) >= _quantidade, "Saldo insuficiente");
        require(bytes(_motivo).length > 0, "Motivo nao pode estar vazio");
        
        _burn(_de, _quantidade);
        
        emit TokensQueimados(_de, _quantidade, _motivo, block.timestamp);
    }
    
    /**
     * @dev Queima tokens do próprio administrador
     * @param _quantidade Quantidade de tokens a queimar
     * @param _motivo Motivo da queima
     */
    function queimarTokens(
        uint256 _quantidade,
        string memory _motivo
    ) public apenasAdministradorRecompensas quantidadeValida(_quantidade) {
        require(balanceOf(msg.sender) >= _quantidade, "Saldo insuficiente");
        require(bytes(_motivo).length > 0, "Motivo nao pode estar vazio");
        
        _burn(msg.sender, _quantidade);
        
        emit TokensQueimados(msg.sender, _quantidade, _motivo, block.timestamp);
    }
    
    /**
     * @dev Obtém o saldo de tokens de um endereço
     * @param _conta Endereço para verificar o saldo
     * @return uint256 Saldo de tokens
     */
    function obterSaldo(address _conta) public view returns (uint256) {
        return balanceOf(_conta);
    }
    
    /**
     * @dev Obtém o total de tokens em circulação
     * @return uint256 Total de tokens
     */
    function obterTotalSupply() public view returns (uint256) {
        return totalSupply();
    }
    
    /**
     * @dev Obtém informações básicas do token
     * @return string Nome do token
     * @return string Símbolo do token
     * @return uint8 Decimais do token
     * @return uint256 Total de tokens em circulação
     */
    function obterInformacoesToken() public view returns (
        string memory,
        string memory,
        uint8,
        uint256
    ) {
        return (name(), symbol(), decimals(), totalSupply());
    }
    
    /**
     * @dev Obtém o histórico de recompensas de um aluno
     * @param _aluno Endereço do aluno
     * @return Recompensa[] Array com histórico de recompensas
     */
    function obterHistoricoRecompensas(address _aluno) 
        public 
        view 
        returns (Recompensa[] memory) 
    {
        return historicoRecompensas[_aluno];
    }
    
    /**
     * @dev Obtém o total de recompensas recebidas por um aluno
     * @param _aluno Endereço do aluno
     * @return uint256 Total de recompensas recebidas
     */
    function obterTotalRecompensasRecebidas(address _aluno) 
        public 
        view 
        returns (uint256) 
    {
        return totalRecompensasRecebidas[_aluno];
    }
    
    /**
     * @dev Adiciona um novo administrador de recompensas
     * @param _novoAdministrador Endereço do novo administrador
     */
    function adicionarAdministradorRecompensas(address _novoAdministrador) public onlyOwner {
        require(_novoAdministrador != address(0), "Endereco invalido");
        require(!administradoresRecompensas[_novoAdministrador], "Ja e administrador");
        
        administradoresRecompensas[_novoAdministrador] = true;
        emit AdministradorRecompensasAdicionado(_novoAdministrador);
    }
    
    /**
     * @dev Remove um administrador de recompensas
     * @param _administrador Endereço do administrador a ser removido
     */
    function removerAdministradorRecompensas(address _administrador) public onlyOwner {
        require(_administrador != owner(), "Nao pode remover o owner");
        require(administradoresRecompensas[_administrador], "Nao e administrador");
        
        administradoresRecompensas[_administrador] = false;
        emit AdministradorRecompensasRemovido(_administrador);
    }
    
    /**
     * @dev Verifica se um endereço é administrador de recompensas
     * @param _endereco Endereço a ser verificado
     * @return bool Verdadeiro se for administrador
     */
    function verificarAdministradorRecompensas(address _endereco) public view returns (bool) {
        return _endereco == owner() || administradoresRecompensas[_endereco];
    }
    
    /**
     * @dev Pausa o contrato (apenas owner)
     */
    function pausarContrato() public onlyOwner {
        _pause();
    }
    
    /**
     * @dev Despausa o contrato (apenas owner)
     */
    function despausarContrato() public onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Override da função transfer para incluir pausa
     */
    function transfer(address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        returns (bool) 
    {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override da função transferFrom para incluir pausa
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        returns (bool) 
    {
        return super.transferFrom(from, to, amount);
    }
} 