// SPDX-License-Identifier: GPL-3.0
// COINK Token

pragma solidity ^0.8.31;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract COINKtoken is ERC20 {
    string public version = "1.0";
    uint256 public constant supply = 22_779_888_555_337_777 * 10 ** 18;

    address public owner;
    address public UBQaddress;
    address public WhitelistManager;

    uint256 private startTimestamp;
    uint256 private releaseInterval;
    uint256 private socialReleaseTimestamp;
    uint256 private foundersFirstReleaseTimestamp;
    uint256 private reserveFirstReleaseTimestamp;

    struct TokenLockInfo {
        uint256 totalLockedAmount;
        uint256 balance;
        uint256 withdrawn;
        uint256 lockTimestamp; // initialLock
        uint256 withdrawPerPeriod;
    }
    //string comment;

    // map wallet address to tokenLock details
    mapping(address => TokenLockInfo) public tokenLock;

    // Número fixo de reservas
    uint8 public constant RESERVES_COUNT = 12;

    // Estrutura da reserva
    struct Reserve {
        string name;
        uint256 amount;
    }

    Reserve[RESERVES_COUNT] public reserves;
    uint256 public totalReserved;

    uint8 internal constant FOUNDERS_RESERVE_ID = 0;

    uint8 internal constant SOCIAL_RESERVE_ID = 1;
    mapping(address => uint256) public socialWhitelist; // valor que cada endereço pode levantar
    uint256 public totalSocialWhitelisted; // total bloqueado na social whitelist

    uint8 internal constant AIRDROP_RESERVE_ID = 2;
    mapping(address => uint256) public whitelist;
    uint256 public totalWhitelisted;

    address[] private founders;
    mapping(address => uint256) public founderAllocation; // saldo inicial (total alocado)
    mapping(address => uint256) public founderClaimed; // já levantado
    uint256 public totalFoundersLocked;

    uint8 internal constant RESERVE_FUND_ID = 7;

    // events
    event MintCOINK(address indexed _wallet, uint256 _value);

    event NewUBQwallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event NewWhitelistManagerWallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    //--------------------------
    // Events

    event WhitelistAdded(address indexed account, uint256 amount);
    event WhitelistClaimed(address indexed account, uint256 amount);

    event FounderClaim(address indexed founder, uint256 amount);

    event SocialWhitelistAdded(address indexed account, uint256 amount);
    event SocialWhitelistClaimed(address indexed account, uint256 amount);

    event ReserveFundWithdrawn(address indexed to, uint256 amount);
    event TransferFromReserve(address indexed to, uint256 amount);

    event BurnCoink(address indexed account, uint256 amount);

    // constructor
    constructor() ERC20("COINK", "COINK") {
        owner = msg.sender;
        UBQaddress = msg.sender;
        WhitelistManager = msg.sender;

        startTimestamp = block.timestamp; // now

        releaseInterval = 30 * (24 * 60 * 60); // 30 days
        socialReleaseTimestamp = startTimestamp + (12 * releaseInterval); // 12 months
        foundersFirstReleaseTimestamp = startTimestamp + (24 * releaseInterval); // 24 months
        reserveFirstReleaseTimestamp = startTimestamp + (48 * releaseInterval); // 48 months

        _mint(address(this), supply);
        emit MintCOINK(address(this), supply);

        uint256 sum;
        sum = 0;
        uint256 reserveValue;

        reserveValue = 232_812_345_678_915 * 10 ** 18; // 1.02%
        reserves[FOUNDERS_RESERVE_ID] = Reserve({
            name: "Founders",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 5_497_551_442_064_137 * 10 ** 18; // 24.13%
        reserves[SOCIAL_RESERVE_ID] = Reserve({
            name: "Social Projects",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 2_711_083_330_947_799 * 10 ** 18; // 11.90%
        reserves[AIRDROP_RESERVE_ID] = Reserve({
            name: "Community Airdrops",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 8_314_166_640_432_130 * 10 ** 18; // 36.50%
        reserves[3] = Reserve({name: "Game Mechanics", amount: reserveValue});
        sum += reserveValue;

        reserveValue = 2_161_080_141_436_955 * 10 ** 18; // 9.49%
        reserves[4] = Reserve({
            name: "Development and Maintenance",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 1_087_972_604_333_698 * 10 ** 18; // 4.78%
        reserves[5] = Reserve({name: "Marketing", amount: reserveValue});
        sum += reserveValue;

        reserveValue = 2_718_281_828 * 10 ** 18; // 0.0000%
        reserves[6] = Reserve({
            name: "Liquidity Provision",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 331_694_471_114 * 10 ** 18; // 0.0015%
        reserves[RESERVE_FUND_ID] = Reserve({
            name: "Reserve Fund",
            amount: reserveValue
        });
        sum += reserveValue;

        reserveValue = 300_813_314_608_369 * 10 ** 18; // 1.32%
        reserves[8] = Reserve({name: "Seed", amount: reserveValue});
        sum += reserveValue;

        reserveValue = 1_018_033_988_555_808 * 10 ** 18; // 4.47%
        reserves[9] = Reserve({name: "Institutions", amount: reserveValue});
        sum += reserveValue;

        reserveValue = 456_040_333_777_130 * 10 ** 18; // 2.00%
        reserves[10] = Reserve({name: "VCs", amount: reserveValue});
        sum += reserveValue;

        reserveValue = 1_000_000_000_749_894 * 10 ** 18; // 4.39%
        reserves[11] = Reserve({name: "Retail", amount: reserveValue});
        sum += reserveValue;

        // Garante que a distribuicao bate com o saldo que o contrato detem
        require(
            sum == balanceOf(address(this)),
            "sum is not equal to contract token balance"
        );

        totalReserved = sum; // inicialmente igual ao balance, mas pode haver depositos no contracto que alterem isto
        totalFoundersLocked = 0;
        totalSocialWhitelisted = 0;
        totalWhitelisted = 0;

        // lista dos founders no construtor Endereços de carteiras aqui!
        founders[0] = address(0x09167858b2D2D69694355E7a6082345E1B3b565C);
        founders[1] = address(0xf188b8cc0b42A485258439f93A55C4a7830814AD);
        founders[2] = address(0x39FA95dDfF5C09DCC2927ef8ECA9f00AECb42AED);
        founders[3] = address(0xFa5B71ad62964578DA4fA2EAca5b71082516b97B);
        founders[4] = address(0xF695b96bC6F7eD94aEd344D4354Ab7e4A27E042B);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not allowed");
        _;
    }

    modifier onlyUBQ() {
        require(msg.sender == UBQaddress, "not allowed");
        _;
    }

    modifier onlyWhitelistManager() {
        require(msg.sender == WhitelistManager, "not allowed");
        _;
    }

    //---------------------------
    // AIRDROP

    // simplificar com função de transferencia directa do airdrop atribuido na hora!

    // Adiciona endereco na whitelist com um valor a levantar (inteiro, sem partes)
    // Debita automaticamente uma reserva que tenha saldo suficiente
    function addWhitelist(
        address account,
        uint256 amount
    ) external onlyWhitelistManager {
        require(account != address(0), "account is zero");
        require(amount > 0, "amount is zero");
        require(whitelist[account] != amount, "possible duplicated airdrop");

        // Escolhe a primeira reserva com saldo suficiente
        require(
            amount < 1_000_000 * 10 ** 18,
            "don't abuse the power of COINK"
        );

        require(
            reserves[AIRDROP_RESERVE_ID].amount >= amount,
            "no reserve with enough funds"
        );

        // Move da reserva para a whitelist (continua dentro do contrato)
        reserves[AIRDROP_RESERVE_ID].amount -= amount;
        totalReserved -= amount;
        totalWhitelisted += amount;

        whitelist[account] += amount;
        emit WhitelistAdded(account, amount);
    }

    // Levantamento: o utilizador retira todo o valor autorizado e fica impedido de novo levantamento
    function claimWhitelist() external {
        uint256 amount = whitelist[msg.sender];
        require(amount > 0, "nothing to claim");

        // clear before transfer
        whitelist[msg.sender] = 0;
        totalWhitelisted -= amount;

        _transfer(address(this), msg.sender, amount);
        emit WhitelistClaimed(msg.sender, amount);
    }

    //----------------------------------------
    // admin functions

    // only owner can replace wallet address of UBQ team
    function setNewUBQwallet(address newUBQaddress) external onlyOwner {
        require(newUBQaddress != address(0), "new address is the zero address");
        require(newUBQaddress != UBQaddress, "Same wallet");
        UBQaddress = newUBQaddress;
        emit NewUBQwallet(UBQaddress, newUBQaddress);
    }

    // only UBQ can replace wallet address of WhiteListManager
    function setNewWhitelistManagerWallet(address newAddress) external onlyUBQ {
        require(newAddress != address(0), "new address is the zero address");
        require(newAddress != WhitelistManager, "Same wallet");
        emit NewWhitelistManagerWallet(WhitelistManager, newAddress);
        WhitelistManager = newAddress;
    }

    function renounceOwnership() public onlyOwner {
        // works only once!
        owner = address(0);
    }

    function COINKbalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function POLbalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ---------- Founders ----------

    // Consulta a lista de founders
    function getFounders() external view returns (address[] memory) {
        return founders;
    }

    // Distribui a totalidade da reserva id 0 de forma equitativa entre os founders
    // Usa divisao inteira: todos recebem 'base', e os primeiros 'remainder' recebem +1 unidade
    // so pode ser usado uma vez
    function distributeToFounders() external onlyOwner {
        uint256 n = founders.length;
        require(n > 0, "no founders");
        uint256 total = reserves[FOUNDERS_RESERVE_ID].amount;
        require(total > 0, "Founders reserve empty");

        // zera a reserva 0 e atualiza totalReserved
        reserves[FOUNDERS_RESERVE_ID].amount = 0;
        totalReserved -= total;
        totalFoundersLocked = total;

        uint256 base = total / n;
        uint256 remainder = total % n;

        for (uint256 i = 0; i < n; i++) {
            uint256 share = base + (i < remainder ? 1 : 0);
            if (share > 0) {
                founderAllocation[founders[i]] = share;
            }
        }
    }

    // Claim com cliff de 24 meses e vesting mensal por 24 meses (total 48).
    // permite ao founder levantar o acumulado do que já venceu, caso tenha ficado meses sem levantar.

    function claimFounderVested() external {
        uint256 allocation = founderAllocation[msg.sender];
        require(allocation > 0, "no allocation");
        require(
            block.timestamp >= foundersFirstReleaseTimestamp,
            "cliff not over"
        );

        // Meses vencidos desde o fim do cliff (inclui o 1o mes no instante do cliff)
        uint256 elapsed = block.timestamp - foundersFirstReleaseTimestamp;
        uint256 monthsVested = (elapsed / releaseInterval) + 1;
        if (monthsVested > 24) monthsVested = 24;

        // Total que deveria estar liberado até agora (inteiro; lida com restos automaticamente)
        uint256 totalVested = (allocation * monthsVested) / 24;

        uint256 claimed = founderClaimed[msg.sender];
        require(totalVested > claimed, "nothing to claim");
        uint256 claimable = totalVested - claimed;

        // Atualiza estado e transfere
        founderClaimed[msg.sender] = claimed + claimable;
        totalFoundersLocked -= claimable;
        _transfer(address(this), msg.sender, claimable);

        emit FounderClaim(msg.sender, claimable);
    }

    // get info about Lock befere UnLock

    function getLockInfo(
        address account
    ) public view returns (uint256 lockedBalance, uint256 lockedTime) {
        if (tokenLock[account].totalLockedAmount == 0) return (0, 0);

        lockedTime = block.timestamp - tokenLock[account].lockTimestamp;
        lockedBalance = tokenLock[account].balance;

        return (lockedBalance, lockedTime);
    }

    //----------------------------
    // Social Project

    // Função para o owner adicionar endereços na SocialWhitelist (debita a reserva 1):
    function addSocialWhitelist(
        address account,
        uint256 amount
    ) external onlyUBQ {
        require(account != address(0), "account is zero");
        require(amount > 0, "amount is zero");
        require(
            reserves[SOCIAL_RESERVE_ID].amount >= amount,
            "insufficient reserve Social Projects"
        );
        // Move da reserva 1 para a SocialWhitelist (continua dentro do contrato)
        reserves[SOCIAL_RESERVE_ID].amount -= amount;
        totalReserved -= amount;

        socialWhitelist[account] += amount; // permite adicionar várias vezes ao mesmo endereço
        totalSocialWhitelisted += amount;

        emit SocialWhitelistAdded(account, amount);
    }

    //Função de claim para as entidades com projectos sociais autorizados (só após 12 meses):
    function claimSocialWhitelist() external {
        require(
            block.timestamp >= socialReleaseTimestamp,
            "social project founds not released yet"
        );

        uint256 amount = socialWhitelist[msg.sender];
        require(amount > 0, "nothing to claim");

        // Zera antes de transferir
        socialWhitelist[msg.sender] = 0;
        totalSocialWhitelisted -= amount;

        _transfer(address(this), msg.sender, amount);
        emit SocialWhitelistClaimed(msg.sender, amount);
    }

    //--------------------------------
    // FUNDO DE RESERVA ID 7

    // Quanto do fundo pode ser levantado agora (0 antes do prazo)
    function reserveFundAvailable() public view returns (uint256) {
        if (block.timestamp < reserveFirstReleaseTimestamp) return 0;
        return reserves[RESERVE_FUND_ID].amount;
    }

    // Levantamento parcial do fundo de reserva (apenas após 48 meses)
    function withdrawReserveFund(uint256 amount) external onlyUBQ {
        require(
            block.timestamp >= reserveFirstReleaseTimestamp,
            "reserve fund locked"
        );
        require(amount > 0, "amount is zero");
        require(
            reserves[FOUNDERS_RESERVE_ID].amount >= amount,
            "insufficient reserve fund"
        );
        reserves[RESERVE_FUND_ID].amount -= amount;
        totalReserved -= amount;

        _transfer(address(this), UBQaddress, amount);
        emit ReserveFundWithdrawn(UBQaddress, amount);
    }

    //------------------------
    // Movimenta fundos das categorias que não tem condicionamentos ao levantamento
    // used to pay for services, add tokens to game mechanics, pay to investors etc etc
    function transferFromReserve(
        uint256 reserveId,
        address to,
        uint256 amount
    ) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "invalid reserve id");
        require(reserveId != FOUNDERS_RESERVE_ID, "invalid reserve id"); // founders have special rules
        require(reserveId != SOCIAL_RESERVE_ID, "invalid reserve id"); // Social Project have special rules
        require(reserveId != AIRDROP_RESERVE_ID, "invalid reserve id"); // Community Airdrop have special rules
        require(reserveId != RESERVE_FUND_ID, "invalid reserve id"); // Reserve Fund have special rules
        require(to != address(0), "to is zero");
        require(amount > 0, "amount is zero");
        require(reserves[reserveId].amount >= amount, "insufficient reserve");

        // Debita a reserva e atualiza totalReserved
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // Transfere tokens do contrato para o destinatario
        _transfer(address(this), to, amount);
        emit TransferFromReserve(to, amount);
    }

    //--------------------------------
    // excedentes

    // Calcula o excedente de tokens no contrato acima do total bloqueado (reservas + whitelist)
    function excessBalance() public view returns (uint256) {
        uint256 bal = balanceOf(address(this));
        uint256 locked = totalReserved +
            totalWhitelisted +
            totalFoundersLocked +
            totalSocialWhitelisted;

        if (bal > locked) return bal - locked;
        else return 0;
    }

    // UBQ pode levantar o excedente
    function withdrawExcess() external onlyUBQ {
        uint256 excess = excessBalance();
        require(excess > 0, "no excess");
        _transfer(address(this), msg.sender, excess);
    }

    // Função receive para rejeitar qualquer envio de POL diretamente para o contrato
    receive() external payable {
        revert("sending POL to the contract is not allowed");
    }

    // Função fallback como segurança adicional para lidar com chamadas não esperadas
    // evitamos receber POL neste contrato
    fallback() external payable {
        revert("the call is not allowed");
    }

    function releaseERC20Tokens(address _tokenId) public onlyUBQ {
        // avoid stuck tokens in the contract

        require(address(this) != _tokenId, "only other Tokens!");

        IERC20 anyTokenContract = IERC20(_tokenId);
        uint256 balance = anyTokenContract.balanceOf(address(this));

        require(balance > 0, "balance is zero");

        anyTokenContract.transfer(msg.sender, balance);
    }

    function releasePOL() public onlyUBQ {
        // avoid stuck POL in the contract

        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");

        (bool ok, ) = msg.sender.call{value: balance}("");
        require(ok, "native transfer failed");
    }

    //------------------------
    // Porco Assado?
    function burnCoink(uint256 reserveId, uint256 amount) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "invalid reserve id");
        require(reserveId != FOUNDERS_RESERVE_ID, "invalid reserve id"); // founders have special rules
        require(reserveId != SOCIAL_RESERVE_ID, "invalid reserve id"); // Social Project have special rules
        require(amount > 0, "amount is zero");
        require(reserves[reserveId].amount >= amount, "insufficient reserve");

        // Debita a reserva e atualiza totalReserved
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // Burn the COINK // porco assado?
        _burn(address(this), amount);

        emit BurnCoink(address(this), amount);
    }
}
