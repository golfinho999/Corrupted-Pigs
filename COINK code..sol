// SPDX-License-Identifier: GPL-3.0
// 🐷💰 COINK Token 💎 – The memecoin for reflective and mischievous pigs
// May your wallets be full, your snouts shiny, and your airdrops always muddy

pragma solidity ^0.8.31;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract COINKtoken is ERC20 {
    string public version = "1.0 (Stylized)";
    uint256 public constant supply = 22_779_888_555_337_777 * 10 ** 18;

    address public owner;
    address public UBQaddress;
    address public AirDropManager;

    uint256 private startTimestamp;
    uint256 private releaseInterval;
    uint256 private socialReleaseTimestamp;
    uint256 private foundersFirstReleaseTimestamp;
    uint256 private reserveFirstReleaseTimestamp;

    struct TokenLockInfo {
        uint256 totalLockedAmount;
        uint256 balance;
        uint256 withdrawn;
        uint256 lockTimestamp; // InitialLock
        uint256 withdrawPerPeriod;
    }

    // Map wallet address to tokenLock details
    mapping(address => TokenLockInfo) public tokenLock;

    // Fixed number of reservations
    uint8 public constant RESERVES_COUNT = 12;

    // Structure of the reserve
    struct Reserve {
        string name;
        uint256 amount;
    }

    Reserve[RESERVES_COUNT] public reserves;
    uint256 public totalReserved;

    uint8 internal constant FOUNDERS_RESERVE_ID = 0;

    uint8 internal constant SOCIAL_RESERVE_ID = 1;
    mapping(address => uint256) public socialWhitelist; // Amount that each address can withdraw
    uint256 public totalSocialWhitelisted; // Total locked in the Social Projects Whitelist

    uint8 internal constant AIRDROP_RESERVE_ID = 2;

    address[] private founders;
    mapping(address => uint256) public founderAllocation; // Initial balance (total allocated)
    mapping(address => uint256) public founderClaimed; // Already withdrawn
    uint256 public totalFoundersLocked;

    uint8 internal constant RESERVE_FUND_ID = 7;

    // Events
    event MintCOINK(address indexed _wallet, uint256 _value);

    event NewUBQwallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event NewAirDropManager(
        address indexed previousAddress,
        address indexed newAddress
    );

    //--------------------------
    // Events

    event AirDropSended(address indexed account, uint256 amount);

    event FounderClaim(address indexed founder, uint256 amount);

    event SocialWhitelistAdded(address indexed account, uint256 amount);
    event SocialWhitelistClaimed(address indexed account, uint256 amount);

    event ReserveFundWithdrawn(address indexed to, uint256 amount);
    event TransferFromReserve(address indexed to, uint256 amount);

    event BurnCoink(address indexed account, uint256 amount);

    // Constructor
    constructor() ERC20("COINK", "COINK") {
        owner = msg.sender;
        UBQaddress = msg.sender;
        AirDropManager = msg.sender;

        startTimestamp = block.timestamp; // Now

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

        // Ensures that the distribution matches the balance held by the contract
        require(
            sum == balanceOf(address(this)),
            "Pride falters: the ledger does not align"
        );

        totalReserved = sum; // Initially equal to the balance, but there may be deposits in the contract that change this
        totalFoundersLocked = 0;
        totalSocialWhitelisted = 0;

        // List of founders in the builder Wallet addresses here!
        founders[0] = address(0x09167858b2D2D69694355E7a6082345E1B3b565C);
        founders[1] = address(0xf188b8cc0b42A485258439f93A55C4a7830814AD);
        founders[2] = address(0x39FA95dDfF5C09DCC2927ef8ECA9f00AECb42AED);
        founders[3] = address(0xFa5B71ad62964578DA4fA2EAca5b71082516b97B);
        founders[4] = address(0xF695b96bC6F7eD94aEd344D4354Ab7e4A27E042B);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Equity denies meddling with consecrated coffers");
        _;
    }

    modifier onlyUBQ() {
        require(msg.sender == UBQaddress, "Integrity preserves what is consecrated");
        _;
    }

    modifier onlyAirDropManager() {
        require(msg.sender == AirDropManager, "Prudence prevents interference in this task");
        _;
    }

    //---------------------------
    // AIRDROP

    // Adds an address to the whitelist with an amount to withdraw (integer, no fractions)
    // Automatically debits a reservation that has sufficient balance
    function sendAirDrop(
        address account,
        uint256 amount
    ) external onlyAirDropManager {
        require(account != address(0), "Providence does not endow the emptiness");
        require(amount > 0, "Lust for COINK comes to naught");

        // Selects the first reservation with sufficient balance
        require(amount < 500_000 * 10 ** 18, "Greed recoils when desire exceeds reason");

        require(
            reserves[AIRDROP_RESERVE_ID].amount >= amount,
            "Detachment accepts that nothing remains to receive"
        );

        // Moves from the reservation to the whitelist (remains within the contract)
        reserves[AIRDROP_RESERVE_ID].amount -= amount;
        totalReserved -= amount;

        _transfer(address(this), account, amount);
        emit AirDropSended(AirDropManager, amount);
    }

    //----------------------------------------
    // Admin functions

    // Only owner can replace wallet address of UBQ team
    function setNewUBQwallet(address newUBQaddress) external onlyOwner {
        require(newUBQaddress != address(0), "Guidance cannot emerge from shadows; choose a living soul");
        require(newUBQaddress != UBQaddress, "Reverence acknowledges this path was already taken");
        UBQaddress = newUBQaddress;
        emit NewUBQwallet(UBQaddress, newUBQaddress);
    }

    // Only UBQ can replace wallet address of WhiteListManager
    function setNewAirDropManager(address newAddress) external onlyUBQ {
        require(newAddress != address(0), "Faith begins before the eyes perceive");
        require(newAddress != AirDropManager, "Patience: the role is already in place");
        emit NewAirDropManager(AirDropManager, newAddress);
        AirDropManager = newAddress;
    }

    function renounceOwnership() public onlyOwner {
        // Works only once!
        owner = address(0);
    }

    function COINKbalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function POLbalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ---------- Founders ----------

    // Checks the list of founders
    function getFounders() external view returns (address[] memory) {
        return founders;
    }

    // Distributes the entirety of reservation ID 0 equally among the founders
    // Uses integer division: everyone receives 'base', and the first 'remainder' receive +1 unit
    // Can only be used once
    function distributeToFounders() external onlyOwner {
        uint256 n = founders.length;
        require(n > 0, "The wise never cease to learn");
        uint256 total = reserves[FOUNDERS_RESERVE_ID].amount;
        require(total > 0, "Wrath finds no fuel in an empty trough");

        // Zeros out Reserve 0 and updates totalReserved
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

    // Claim with a 24-month cliff and monthly vesting over 24 months (total 48)
    // Allows the founder to withdraw the accumulated amount that has already vested, in case they haven’t withdrawn for several months

    function claimFounderVested() external {
        uint256 allocation = founderAllocation[msg.sender];
        require(allocation > 0, "Discernment reveals no seed was ever planted");
        require(
            block.timestamp >= foundersFirstReleaseTimestamp,
            "Stewardship releases only what has ripened"
        );

        // Months vested since the end of the cliff (includes the 1st month at the moment the cliff ends)
        uint256 elapsed = block.timestamp - foundersFirstReleaseTimestamp;
        uint256 monthsVested = (elapsed / releaseInterval) + 1;
        if (monthsVested > 24) monthsVested = 24;

        // Total that should have been released up to now (integer; handles remainders automatically)
        uint256 totalVested = (allocation * monthsVested) / 24;

        uint256 claimed = founderClaimed[msg.sender];
        require(totalVested > claimed, "Tranquility bestows only what is ready");
        uint256 claimable = totalVested - claimed;

        // Updates state and transfers
        founderClaimed[msg.sender] = claimed + claimable;
        totalFoundersLocked -= claimable;
        _transfer(address(this), msg.sender, claimable);

        emit FounderClaim(msg.sender, claimable);
    }

    // Get info about Lock before UnLock

    function getLockInfo(
        address account
    ) public view returns (uint256 lockedBalance, uint256 lockedTime) {
        if (tokenLock[account].totalLockedAmount == 0) return (0, 0);

        lockedTime = block.timestamp - tokenLock[account].lockTimestamp;
        lockedBalance = tokenLock[account].balance;

        return (lockedBalance, lockedTime);
    }

    //----------------------------
    // Social Projects

    // Function for the owner to add addresses to the SocialWhitelist (debited from Reserve 1)
    function addSocialWhitelist(
        address account,
        uint256 amount
    ) external onlyUBQ {
        require(account != address(0), "Purpose cannot flow to emptiness");
        require(amount > 0, "Modesty appreciates even small offerings");
        require(
            reserves[SOCIAL_RESERVE_ID].amount >= amount,
            "Harmony rejects actions that disrupt this balance"
        );
        // Moves from Reserve 1 to the SocialWhitelist (remains within the contract)
        reserves[SOCIAL_RESERVE_ID].amount -= amount;
        totalReserved -= amount;

        socialWhitelist[account] += amount; // Allows adding multiple times to the same address
        totalSocialWhitelisted += amount;

        emit SocialWhitelistAdded(account, amount);
    }

    // Claim function for authorized Social Project entities (only after 12 months)
    function claimSocialWhitelist() external {
        require(
            block.timestamp >= socialReleaseTimestamp,
            "Serenity prevails; your rewards await their appointed time"
        );

        uint256 amount = socialWhitelist[msg.sender];
        require(amount > 0, "Jubilee rests until the harvest is ready");

        // Zeros out before transferring
        socialWhitelist[msg.sender] = 0;
        totalSocialWhitelisted -= amount;

        _transfer(address(this), msg.sender, amount);
        emit SocialWhitelistClaimed(msg.sender, amount);
    }

    //--------------------------------
    // RESERVE FUND ID 7

    // How much of the fund can be withdrawn now (0 before the deadline)
    function reserveFundAvailable() public view returns (uint256) {
        if (block.timestamp < reserveFirstReleaseTimestamp) return 0;
        return reserves[RESERVE_FUND_ID].amount;
    }

    // Partial withdrawal from the Reserve Fund (only after 48 months)
    function withdrawReserveFund(uint256 amount) external onlyUBQ {
        require(
            block.timestamp >= reserveFirstReleaseTimestamp,
            "Faith keeps this fund sealed from corrupted hands"
        );
        require(amount > 0, "Humility reminds: nothing given is still nothing");
        require(
            reserves[FOUNDERS_RESERVE_ID].amount >= amount,
            "Fortitude falters; the Founders’ trough is empty"
        );
        reserves[RESERVE_FUND_ID].amount -= amount;
        totalReserved -= amount;

        _transfer(address(this), UBQaddress, amount);
        emit ReserveFundWithdrawn(UBQaddress, amount);
    }

    //------------------------
    // Moves funds from categories that have no withdrawal restrictions
    // Used to pay for services, add tokens to game mechanics, pay to investors etc., etc.
    function transferFromReserve(
        uint256 reserveId,
        address to,
        uint256 amount
    ) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "Envy cannot find this pen; it does not exist");
        require(reserveId != FOUNDERS_RESERVE_ID, "Order denies you standing in this moment"); // Founders have special rules
        require(reserveId != SOCIAL_RESERVE_ID, "Restraint bars this action before it begins"); // Social Projects hahave special rules
        require(reserveId != AIRDROP_RESERVE_ID, "Chastity is protected; hands off"); // Community Airdrop has special rules
        require(reserveId != RESERVE_FUND_ID, "Faith guards the Reserve; intruders denied"); // Reserve Fund has special rules
        require(to != address(0), "Sagacity cannot steer a phantom path");
        require(amount > 0, "Generosity cannot flow from emptiness");
        require(reserves[reserveId].amount >= amount, "Contentment denies what cannot rightly be yours");

        // Debits the reservation and updates totalReserved
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // Transfers tokens from the contract to the recipient
        _transfer(address(this), to, amount);
        emit TransferFromReserve(to, amount);
    }

    //--------------------------------
    // Excesses

    // Calculates the surplus tokens in the contract above the total locked (Reserves + Whitelist)
    function excessBalance() public view returns (uint256) {
        uint256 bal = balanceOf(address(this));
        uint256 locked = totalReserved +
            totalFoundersLocked +
            totalSocialWhitelisted;

        if (bal > locked) return bal - locked;
        else return 0;
    }

    // UBQ can withdraw the surplus
    function withdrawExcess() external onlyUBQ {
        uint256 excess = excessBalance();
        require(excess > 0, "Temperance finds no surplus to claim");
        _transfer(address(this), msg.sender, excess);
    }

    // Receive function to reject any POL sent directly to the contract
    receive() external payable {
        revert("Sobriety forbids reckless POL offerings at this gate");
    }

    // Fallback function as an additional safety measure to handle unexpected calls
    // We prevent receiving POL in this contract
    fallback() external payable {
        revert("Diligence rejects the unfocused call");
    }

    function releaseERC20Tokens(address _tokenId) public onlyUBQ {
        // Avoid stuck tokens in the contract

        require(address(this) != _tokenId, "Gluttony denied: COINK cannot consume itself");

        IERC20 anyTokenContract = IERC20(_tokenId);
        uint256 balance = anyTokenContract.balanceOf(address(this));

        require(balance > 0, "Intent cannot awaken what is not yet ready");

        anyTokenContract.transfer(msg.sender, balance);
    }

    function releasePOL() public onlyUBQ {
        // Avoid stuck POL in the contract

        uint256 balance = address(this).balance;
        require(balance > 0, "Virtue’s barn is empty; no COINK to harvest");

        (bool ok, ) = msg.sender.call{value: balance}("");
        require(ok, "Sloth leaves the offering unmade");
    }

    //------------------------
    // Roast Pork
    function burnCoink(uint256 reserveId, uint256 amount) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "Covet cannot locate this pen for burning");
        require(reserveId != FOUNDERS_RESERVE_ID, "Justice forbids altering what is sacred"); // Founders have special rules
        require(reserveId != SOCIAL_RESERVE_ID, "Will refuses to bend to unauthorized intent"); // Social Project has special rules
        require(amount > 0, "Desire must wait: nothing to act upon");
        require(reserves[reserveId].amount >= amount, "Avarice blocks this attempt: the reserve is too small");

        // Debits the reservation and updates totalReserved
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // Burn the COINK
        _burn(address(this), amount);

        emit BurnCoink(address(this), amount);
    }
}
