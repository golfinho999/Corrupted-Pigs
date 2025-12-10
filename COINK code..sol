// SPDX-License-Identifier: GPL-3.0
// COINK Token

pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract COINKtoken is ERC20 {
    IERC20 public euroToken;
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
        string comment;
    }

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

    mapping(address => uint256) public whitelist;
    uint256 public totalWhitelisted;

    address[] private founders;
    mapping(address => uint256) public founderAllocation; // saldo inicial (total alocado)
    mapping(address => uint256) public founderClaimed; // já levantado
    uint256 public totalFoundersLocked;

    // events
    event MintCOINK(address indexed _wallet, uint256 _value);
    //  event BurnUBQ(address indexed _wallet, uint256 _value);
    event NewUBQwallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event NewWhitelistManagerWallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event WhitelistAdded(address indexed account, uint256 amount);
    event WhitelistClaimed(address indexed account, uint256 amount);

    event FounderClaim(address indexed founder, uint256 amount);

    // constructor
    constructor() ERC20("CORRUPTED PIGS", "COINK") {
        owner = msg.sender;
        UBQaddress = msg.sender;
        WhitelistManager = msg.sender;

        startTimestamp = block.timestamp; // now

        releaseInterval = 30 * (24 * 60 * 60); // 30 days
        socialReleaseTimestamp = startTimestamp + (12 * releaseInterval); // 12 months
        foundersFirstReleaseTimestamp = startTimestamp + (24 * releaseInterval); // 24 months
        reserveFirstReleaseTimestamp = startTimestamp + (36 * releaseInterval); // 36 months

        _mint(address(this), supply);
        emit MintCOINK(msg.sender, supply);

        uint256 sum;
        sum = 0;
        uint256 valueReserve;

        valueReserve = 232_812_345_678_915 * 10 ** 18; // 1.02%
        reserves[0] = Reserve({name: "Founders", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 5_497_551_442_064_137 * 10 ** 18; // 24.13%
        reserves[1] = Reserve({name: "Social Projects", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 2_711_083_330_947_799 * 10 ** 18; // 11.90%
        reserves[2] = Reserve({
            name: "Community Airdrops",
            amount: valueReserve
        });
        sum += valueReserve;

        valueReserve = 8_314_166_640_432_130 * 10 ** 18; // 36.50%
        reserves[3] = Reserve({name: "Game Mechanics", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 2_161_080_141_436_955 * 10 ** 18; // 9.49%
        reserves[4] = Reserve({
            name: "Development and Maintenance",
            amount: valueReserve
        });
        sum += valueReserve;

        valueReserve = 1_087_972_604_333_698 * 10 ** 18; // 4.78%
        reserves[5] = Reserve({name: "Marketing", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 2_718_281_828 * 10 ** 18; // 0.0000%
        reserves[6] = Reserve({
            name: "Liquidity Provision",
            amount: valueReserve
        });
        sum += valueReserve;

        valueReserve = 331_694_471_114 * 10 ** 18; // 0.0015%
        reserves[7] = Reserve({name: "Reserve Fund", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 300_813_314_608_369 * 10 ** 18; // 1.32%
        reserves[8] = Reserve({name: "Seed", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 1_018_033_988_555_808 * 10 ** 18; // 4.47%
        reserves[9] = Reserve({name: "Institutions", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 456_040_333_777_130 * 10 ** 18; // 2.00%
        reserves[10] = Reserve({name: "VCs", amount: valueReserve});
        sum += valueReserve;

        valueReserve = 1_000_000_000_749_894 * 10 ** 18; // 4.39%
        reserves[11] = Reserve({name: "Retail", amount: valueReserve});
        sum += valueReserve;

        // Garante que a distribuicao bate com o saldo que o contrato detem
        require(
            sum == balanceOf(address(this)),
            "sum is not equal to contract token balance"
        );

        totalReserved = sum; // inicialmente igual ao balance, mas pode haver depositos no contracto que alterem isto
        totalWhitelisted = 0;
        totalFoundersLocked = 0;

        // lista dos founders no construtor Endereços de carteiras aqui!
        founders[0] = address(0x00000000000002343424);
        founders[1] = address(0x00000000000002343424);
        founders[2] = address(0x00000000000002343424);
        founders[3] = address(0x00000000000002343424);
        founders[4] = address(0x00000000000002343424);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    // Distribui tokens a partir de uma reserva para um destinatario
    function transferFromReserve(
        uint256 reserveId,
        address to,
        uint256 amount
    ) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "invalid reserve id");
        require(reserveId != 0, "invalid reserve id"); // founders have special rules
        require(reserveId != 1, "invalid reserve id"); // Social Project have special rules
        require(reserveId != 2, "invalid reserve id"); // Community Airdrop have special rules
        require(reserveId != 7, "invalid reserve id"); // Reserve Fund have special rules
        require(to != address(0), "to is zero");
        require(amount > 0, "amount is zero");
        require(reserves[reserveId].amount >= amount, "insufficient reserve");

        // Debita a reserva e atualiza totalReserved
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // Transfere tokens do contrato para o destinatario
        _transfer(address(this), to, amount);
    }

    // Adiciona endereco na whitelist com um valor a levantar (inteiro, sem partes)
    // Debita automaticamente uma reserva que tenha saldo suficiente
    function addWhitelist(
        address account,
        uint256 amount
    ) external onlyWhitelistManager {
        require(account != address(0), "account is zero");
        require(amount > 0, "amount is zero");
        require(whitelist[account] == 0, "already whitelisted");

        // Escolhe a primeira reserva com saldo suficiente
        require(
            amount < 1_000_000 * 10 ** 18,
            "don't abuse the power of COINK"
        );

        require(reserves[3].amount >= amount, "no reserve with enough funds");

        // Move da reserva para a whitelist (continua dentro do contrato)
        reserves[3].amount -= amount;
        totalReserved -= amount;
        totalWhitelisted += amount;

        whitelist[account] = amount;
        emit WhitelistAdded(account, amount);
    }

    // Levantamento: o usuario retira todo o valor autorizado e fica impedido de novo levantamento
    function claimWhitelist() external {
        uint256 amount = whitelist[msg.sender];
        require(amount > 0, "nothing to claim");

        // clear before transfer
        whitelist[msg.sender] = 0;
        totalWhitelisted -= amount;

        _transfer(address(this), msg.sender, amount);
        emit WhitelistClaimed(msg.sender, amount);
    }

    // Função receive para rejeitar qualquer envio de POL diretamente para o contrato
    receive() external payable {
        revert("sending POL to the contract is not allowed");
    }

    // Função fallback como segurança adicional para lidar com chamadas não esperadas
    // evitamos receber outros token ERC20 neste contrato
    // apenas a função Exchange deve funcionar
    fallback() external payable {
        revert("the call is not allowed");
    }

    function renounceOwnership() public onlyOwner {
        // só pode ser evocado uma vez.
        owner = address(0);
    }

    // only owner can replace wallet address of UBQ team
    function setNewUBQwallet(address newUBQaddress) external onlyOwner {
        require(newUBQaddress != address(0), "new address is the zero address");
        emit NewUBQwallet(UBQaddress, newUBQaddress);
        UBQaddress = newUBQaddress;
    }

    // only UBQ can replace wallet address of WhiteListManager
    function setNewWhitelistManagerWallet(address newAddress) external onlyUBQ {
        require(newAddress != address(0), "new address is the zero address");
        emit NewWhitelistManagerWallet(WhitelistManager, newAddress);
        WhitelistManager = newAddress;
    }

    // Calcula o excedente de tokens no contrato acima do total bloqueado (reservas + whitelist)
    function excessBalance() public view returns (uint256) {
        uint256 bal = balanceOf(address(this));
        uint256 locked = totalReserved + totalWhitelisted + totalFoundersLocked;

        if (bal > locked) return bal - locked;
        else return 0;
    }

    // UBQ pode levantar o excedente
    function withdrawExcess() external onlyUBQ {
        uint256 excess = excessBalance();
        require(excess > 0, "no excess");
        _transfer(address(this), msg.sender, excess);
    }

    function COINKbalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function POLbalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    function COINKtotalSupply() public view returns (uint256) {
        return totalSupply();
    }*/

    // ---------- Founders ----------

    // Consulta a lista de founders
    function getFounders() external view returns (address[] memory) {
        return founders;
    }

    // Distribui a totalidade da reserva id 0 de forma equitativa entre os founders
    // Usa divisao inteira: todos recebem 'base', e os primeiros 'remainder' recebem +1 unidade
    function distributeToFounders() external onlyOwner {
        uint256 n = founders.length;
        require(n > 0, "no founders");
        uint256 total = reserves[0].amount;
        require(total > 0, "reserve 0 empty");

        // zera a reserva 0 e atualiza totalReserved
        reserves[0].amount = 0;
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

    // ?claim? com cliff de 24 meses e vesting mensal por 24 meses (total 48).
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
}
