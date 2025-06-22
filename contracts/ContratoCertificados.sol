// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ContratoCertificados
 * @dev Contrato inteligente para emissão e verificação de certificados digitais educacionais
 * @author Equipe de Desenvolvimento
 */
contract ContratoCertificados is Ownable, Pausable, ReentrancyGuard {
    // Substitui Counters.Counter por uint256
    uint256 private _contadorCertificados;
    
    // Estrutura de dados para um certificado
    struct Certificado {
        uint256 id;
        address enderecoAluno;
        string nomeAluno;
        string nomeCurso;
        uint256 dataEmissao;
        bool valido;
        string hashCertificado;
        string descricaoCurso;
        uint256 cargaHoraria;
        string instituicaoEmissora;
    }
    
    // Mapeamentos para armazenamento de dados
    mapping(uint256 => Certificado) public certificados;
    mapping(address => uint256[]) public certificadosPorAluno;
    mapping(string => uint256) public hashParaId;
    mapping(address => bool) public administradores;
    
    // Eventos para acompanhamento de ações
    event CertificadoEmitido(
        uint256 indexed idCertificado,
        address indexed enderecoAluno,
        string nomeAluno,
        string nomeCurso,
        uint256 dataEmissao,
        string hashCertificado
    );
    
    event CertificadoRevogado(
        uint256 indexed idCertificado,
        address indexed enderecoAluno,
        uint256 dataRevogacao
    );
    
    event AdministradorAdicionado(address indexed administrador);
    event AdministradorRemovido(address indexed administrador);
    
    // Modificadores de acesso
    modifier apenasAdministrador() {
        require(
            msg.sender == owner() || administradores[msg.sender],
            "Apenas administradores podem executar esta acao"
        );
        _;
    }
    
    modifier certificadoExiste(uint256 _idCertificado) {
        require(_idCertificado > 0 && _idCertificado <= _contadorCertificados, 
                "Certificado nao existe");
        _;
    }
    
    constructor() Ownable(msg.sender) {
        administradores[msg.sender] = true;
    }
    
    /**
     * @dev Emite um novo certificado digital
     * @param _enderecoAluno Endereço da carteira do aluno
     * @param _nomeAluno Nome completo do aluno
     * @param _nomeCurso Nome do curso ou evento
     * @param _hashCertificado Hash único do certificado
     * @param _descricaoCurso Descrição detalhada do curso
     * @param _cargaHoraria Carga horária em horas
     * @param _instituicaoEmissora Nome da instituição emissora
     */
    function emitirCertificado(
        address _enderecoAluno,
        string memory _nomeAluno,
        string memory _nomeCurso,
        string memory _hashCertificado,
        string memory _descricaoCurso,
        uint256 _cargaHoraria,
        string memory _instituicaoEmissora
    ) public apenasAdministrador whenNotPaused nonReentrant {
        require(_enderecoAluno != address(0), "Endereco do aluno invalido");
        require(bytes(_nomeAluno).length > 0, "Nome do aluno nao pode estar vazio");
        require(bytes(_nomeCurso).length > 0, "Nome do curso nao pode estar vazio");
        require(bytes(_hashCertificado).length > 0, "Hash do certificado nao pode estar vazio");
        require(hashParaId[_hashCertificado] == 0, "Hash do certificado ja existe");
        
        uint256 novoId = ++_contadorCertificados;
        
        Certificado memory novoCertificado = Certificado({
            id: novoId,
            enderecoAluno: _enderecoAluno,
            nomeAluno: _nomeAluno,
            nomeCurso: _nomeCurso,
            dataEmissao: block.timestamp,
            valido: true,
            hashCertificado: _hashCertificado,
            descricaoCurso: _descricaoCurso,
            cargaHoraria: _cargaHoraria,
            instituicaoEmissora: _instituicaoEmissora
        });
        
        certificados[novoId] = novoCertificado;
        certificadosPorAluno[_enderecoAluno].push(novoId);
        hashParaId[_hashCertificado] = novoId;
        
        emit CertificadoEmitido(
            novoId,
            _enderecoAluno,
            _nomeAluno,
            _nomeCurso,
            block.timestamp,
            _hashCertificado
        );
    }
    
    /**
     * @dev Revoga um certificado existente
     * @param _idCertificado ID do certificado a ser revogado
     */
    function revogarCertificado(uint256 _idCertificado) 
        public 
        apenasAdministrador 
        certificadoExiste(_idCertificado) 
    {
        require(certificados[_idCertificado].valido, "Certificado ja foi revogado");
        
        certificados[_idCertificado].valido = false;
        
        emit CertificadoRevogado(_idCertificado, certificados[_idCertificado].enderecoAluno, block.timestamp);
    }
    
    /**
     * @dev Verifica se um certificado é válido
     * @param _idCertificado ID do certificado
     * @return bool Verdadeiro se o certificado for válido
     */
    function verificarValidadeCertificado(uint256 _idCertificado) 
        public 
        view 
        certificadoExiste(_idCertificado) 
        returns (bool) 
    {
        return certificados[_idCertificado].valido;
    }
    
    /**
     * @dev Obtém os dados completos de um certificado
     * @param _idCertificado ID do certificado
     * @return Certificado Dados completos do certificado
     */
    function obterCertificado(uint256 _idCertificado) 
        public 
        view 
        certificadoExiste(_idCertificado) 
        returns (Certificado memory) 
    {
        return certificados[_idCertificado];
    }
    
    /**
     * @dev Obtém todos os IDs de certificados de um aluno
     * @param _enderecoAluno Endereço da carteira do aluno
     * @return uint256[] Array com IDs dos certificados
     */
    function obterCertificadosDoAluno(address _enderecoAluno) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return certificadosPorAluno[_enderecoAluno];
    }
    
    /**
     * @dev Verifica um certificado pelo hash
     * @param _hashCertificado Hash do certificado
     * @return uint256 ID do certificado se encontrado, 0 caso contrário
     */
    function verificarCertificadoPorHash(string memory _hashCertificado) 
        public 
        view 
        returns (uint256) 
    {
        return hashParaId[_hashCertificado];
    }
    
    /**
     * @dev Obtém o total de certificados emitidos
     * @return uint256 Total de certificados
     */
    function obterTotalCertificados() public view returns (uint256) {
        return _contadorCertificados;
    }
    
    /**
     * @dev Obtém o total de certificados de um aluno
     * @param _enderecoAluno Endereço da carteira do aluno
     * @return uint256 Total de certificados do aluno
     */
    function obterQuantidadeCertificadosAluno(address _enderecoAluno) 
        public 
        view 
        returns (uint256) 
    {
        return certificadosPorAluno[_enderecoAluno].length;
    }
    
    /**
     * @dev Adiciona um novo administrador
     * @param _novoAdministrador Endereço do novo administrador
     */
    function adicionarAdministrador(address _novoAdministrador) public onlyOwner {
        require(_novoAdministrador != address(0), "Endereco invalido");
        require(!administradores[_novoAdministrador], "Ja e administrador");
        
        administradores[_novoAdministrador] = true;
        emit AdministradorAdicionado(_novoAdministrador);
    }
    
    /**
     * @dev Remove um administrador
     * @param _administrador Endereço do administrador a ser removido
     */
    function removerAdministrador(address _administrador) public onlyOwner {
        require(_administrador != owner(), "Nao pode remover o owner");
        require(administradores[_administrador], "Nao e administrador");
        
        administradores[_administrador] = false;
        emit AdministradorRemovido(_administrador);
    }
    
    /**
     * @dev Verifica se um endereço é administrador
     * @param _endereco Endereço a ser verificado
     * @return bool Verdadeiro se for administrador
     */
    function verificarAdministrador(address _endereco) public view returns (bool) {
        return _endereco == owner() || administradores[_endereco];
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
} 