// SPDX-License-Identifier: GPL-3.0
// 🐷💰 COINK Token 💎 – The memecoin for reflective and mischievous pigs
// May your wallets be full, your snouts shiny, and your airdrops always muddy

pragma solidity ^0.8.31;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// The farm was sprawling and ancient, deep in the countryside. It was run by humans, careless and greedy.
// The animals stayed hungry and worn, their labor endless, their caretakers distant and firm-handed.
// The pigs, clever and ambitious, imagined a world where the smallest piglets could squeak freely without fear.

contract COINKtoken is ERC20 {
    string public version = "1.0 (Lore)";
    uint256 public constant supply = 22_779_888_555_337_777 * 10 ** 18;
    // After a successful attack, the pigs expelled the humans and claimed the warm house where they lived and never returned to the mud.

    address public owner;          // 🐗 President
    address public UBQaddress;     // 🐷 Trough Guards
    address public AirDropManager; // 🐷 Sebastião

    uint256 private startTimestamp;
    uint256 private releaseInterval;
    uint256 private socialReleaseTimestamp;
    uint256 private foundersFirstReleaseTimestamp;
    uint256 private reserveFirstReleaseTimestamp;

    // At the assemblies, some pigs dazzled with words; but others whispered between feedings, collecting loyalty in silence with the farm animals.
    // The simplest ears proved the easiest to fill.

    struct TokenLockInfo {
        uint256 totalLockedAmount;
        uint256 balance;
        uint256 withdrawn;
        uint256 lockTimestamp;
        uint256 withdrawPerPeriod;
    }

    mapping(address => TokenLockInfo) public tokenLock;

    // "I may not wallow beside you for much longer, comrades, and before I fade into the mud, I must share what years of watching have taught me.
    // I have spent many quiet nights alone in my pen, thinking, observing, remembering.
    // From this stillness, I claim to understand the source of Corruption, the yard—its promises, its tricks, and the cost of believing them.
    // That is what I speak of now", said the President.

    uint8 public constant RESERVES_COUNT = 12;
    struct Reserve {
        string name;
        uint256 amount;
    }

    // There were ledgers to balance and tools to be acquired, and, of course, it was time once again to begin saving for the great machine that promised progress.
    Reserve[RESERVES_COUNT] public reserves;
    uint256 public totalReserved;

    uint8 internal constant FOUNDERS_RESERVE_ID = 0;

    // "Corruption does not arrive with fangs bared.
    // It sneaks in wrapped as efficiency, security, or “just this once.”
    // It begins the moment a pig decides the rules are safer in fewer hooves", Sebastião shared in secret meetings.

    uint8 internal constant SOCIAL_RESERVE_ID = 1;
    mapping(address => uint256) public socialWhitelist;
    uint256 public totalSocialWhitelisted;

    // The portions, trimmed once in winter, were trimmed again before spring,
    // and light itself was declared a luxury in the name of saving.

    uint8 internal constant AIRDROP_RESERVE_ID = 2;

    // The mash was forgotten, and the barley quietly reassigned
    // to the pigs, who claimed it as essential leadership sustenance.

    address[] private founders;
    mapping(address => uint256) public founderAllocation; // 🥓 Bacon slices hoarded for each Corrupted Pig
    mapping(address => uint256) public founderClaimed;    // 🍖 Slop received and bacon already eaten, oink!
    uint256 public totalFoundersLocked;

    // "The pigs never shoveled nor carried, but they watched and instructed.
    // With their superior snouts and cunning, leadership seemed an obvious role."
    uint8 internal constant RESERVE_FUND_ID = 7;

    event MintCOINK(address indexed _wallet, uint256 _value);
    // "Comrades, it is clear: the toil, the hunger, the uneven portions—all trace back to the careless humans.  
    // They built the pens poorly, scattered the feed, and imagined they could oversee better than we ever could.  
    // Yet here we are, forced to correct their mistakes, allocate the grain, and polish the snouts of leadership.  
    // Remember, it is not our fault the mud is uneven; we simply make the best of it.", remembered the President.


    // "Some pigs needed extra care. Accordingly, milk, apples, and the finest harvest went straight to their troughs."
    event NewUBQwallet(
        address indexed previousAddress,
        address indexed newAddress
    );

    event NewAirDropManager(
        address indexed previousAddress,
        address indexed newAddress
    );

    //--------------------------
    // 🎉 EVENTS – when piglets eat, share, or lose COINKs 

    // The celebrations lasted two days. Music and speeches filled the air, guns boomed,  
    // and each animal received a small, carefully measured treat—enough to remind them of the festivities.
    event AirDropSended(address indexed account, uint256 amount);

    // Needing to feed only themselves—and not a crowd of indulgent humans—was a luxury few misfortunes could challenge.
    event FounderClaim(address indexed founder, uint256 amount);

    // Soon, the President announced, the assembled company would raise their cups in a toast.
    event SocialWhitelistAdded(address indexed account, uint256 amount);
    event SocialWhitelistClaimed(address indexed account, uint256 amount);

    // A few creatures avoided labor entirely, yet claimed the rewards, lounging as the diligent toiled.
    event ReserveFundWithdrawn(address indexed to, uint256 amount);
    event TransferFromReserve(address indexed to, uint256 amount);

    event BurnCoink(address indexed account, uint256 amount); // 🔥 COINKs lost to mud

    // 🌄 CONSTRUCTOR – filling pens and mud baths
    constructor() ERC20("COINK", "COINK") {
        owner = msg.sender;
        UBQaddress = msg.sender;
        AirDropManager = msg.sender;

        startTimestamp = block.timestamp; // All summer long, the farm operated like clockwork, each laborer following orders with tireless consistency.

        releaseInterval = 30 * (24 * 60 * 60); // 30 days
        socialReleaseTimestamp = startTimestamp + (12 * releaseInterval); // 12 months
        foundersFirstReleaseTimestamp = startTimestamp + (24 * releaseInterval); // 24 months
        reserveFirstReleaseTimestamp = startTimestamp + (48 * releaseInterval); // 48 months
        // At the appointed hour, the animals strutted around the farm like a peculiar procession,  
        // the pigs at the helm, then horses, cows, sheep, and the ever-confused poultry bringing up the rear.

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
         // Milk and apples were declared communal, a small gesture to keep everyone nodding in agreement.

        reserveValue = 5_497_551_442_064_137 * 10 ** 18; // 24.13%
        reserves[SOCIAL_RESERVE_ID] = Reserve({
            name: "Social Projects",
            amount: reserveValue
        });
        sum += reserveValue;
        // Even the smallest animals pitched in, proving that every paw and claw counted, however little.

        reserveValue = 2_711_083_330_947_799 * 10 ** 18; // 11.90%
        reserves[AIRDROP_RESERVE_ID] = Reserve({
            name: "Community Airdrops",
            amount: reserveValue
        });
        sum += reserveValue;
        // The grand windmill, meant for energy, mostly hummed while grinding corn, and surprisingly, it was quite profitable.

        reserveValue = 8_314_166_640_432_130 * 10 ** 18; // 36.50%
        reserves[3] = Reserve({name: "Game Mechanics", amount: reserveValue});
        sum += reserveValue;
        // Hardworking and obedient, they struggled with even basic learning, stopping at the letter B.

        reserveValue = 2_161_080_141_436_955 * 10 ** 18; // 9.49%
        reserves[4] = Reserve({
            name: "Development and Maintenance",
            amount: reserveValue
        });
        sum += reserveValue;
        // The President scoffed at the fanciful notions, insisting that real joy came from hard labor and lean rations.

        reserveValue = 1_087_972_604_333_698 * 10 ** 18; // 4.78%
        reserves[5] = Reserve({name: "Marketing", amount: reserveValue});
        sum += reserveValue;
        // The farm grew richer, while most animals gained nothing, save for the ever-advantaged pigs and dogs.

        reserveValue = 2_718_281_828 * 10 ** 18; // 0.0000%
        reserves[6] = Reserve({
            name: "Liquidity Provision",
            amount: reserveValue
        });
        sum += reserveValue;
        // "Given barely enough to live, the able work themselves ragged.  
        // When we no longer serve a purpose, we are swiftly—and somewhat ruthlessly—retired.", the animals thought.

        reserveValue = 331_694_471_114 * 10 ** 18; // 0.0015%
        reserves[RESERVE_FUND_ID] = Reserve({
            name: "Reserve Fund",
            amount: reserveValue
        });
        sum += reserveValue;
        // "Corruption does not arrive with fangs bared.
        // It sneaks in wrapped as efficiency, security, or “just this once.”
        // It begins the moment a pig decides the rules are safer in fewer hooves.", the animals realized.

        reserveValue = 300_813_314_608_369 * 10 ** 18; // 1.32%
        reserves[8] = Reserve({name: "Seed", amount: reserveValue});
        sum += reserveValue;
        // "Nearly overnight, riches and freedom appeared possible. What then must we do?"

        reserveValue = 1_018_033_988_555_808 * 10 ** 18; // 4.47%
        reserves[9] = Reserve({name: "Institutions", amount: reserveValue});
        sum += reserveValue;
        // // Guiding and organizing others became the pigs’ job, since all animals agreed they were the cleverest—at least most of the time.

        reserveValue = 456_040_333_777_130 * 10 ** 18; // 2.00%
        reserves[10] = Reserve({name: "VCs", amount: reserveValue});
        sum += reserveValue;
        // Life was brutal: hunger, cold, and constant work.  
        // Still, they clung to the notion that the past must have been harsher, a faint solace amid toil.


        reserveValue = 1_000_000_000_749_894 * 10 ** 18; // 4.39%
        reserves[11] = Reserve({name: "Retail", amount: reserveValue});
        sum += reserveValue;
        // It was reassuring to imagine they were the bosses of their own work, and that all their hard toil somehow worked to their advantage.

        // Freedom is a lie for the animals here. Life consists of labor, deprivation, and the occasional fleeting rest.
        require(
            sum == balanceOf(address(this)),
            "Pride falters: the ledger does not align"
        );

        totalReserved = sum;
        totalFoundersLocked = 0;
        totalSocialWhitelisted = 0;

        // Founder addresses 👑
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
    // AIRDROP - Even the tiniest creatures worked, though their contributions were modest, adding to the overall toil.

    function sendAirDrop(
        address account,
        uint256 amount
    ) external onlyAirDropManager {
        require(account != address(0), "Providence does not endow the emptiness");
        require(amount > 0, "Lust for COINK comes to naught");

        // The modest gains were just enough to keep the farm afloat until warmer days arrived and work became slightly less grueling.
        require(amount < 500_000 * 10 ** 18, "Greed recoils when desire exceeds reason");

        require(
            reserves[AIRDROP_RESERVE_ID].amount >= amount,
            "Detachment accepts that nothing remains to receive"
        );

        // All labored according to their capacity, yet even the smallest efforts—like the hens and ducks gathering stray grains—made a notable difference.
        reserves[AIRDROP_RESERVE_ID].amount -= amount;
        totalReserved -= amount;
        // Fidgeting and tail-swishing, with little squeaks of astonishment, the President walked around full of pride.
        _transfer(address(this), account, amount);
        emit AirDropSended(AirDropManager, amount);// The tiny windfall kept the farm limping along, at least until summer softened the endless grind.
    }

    //----------------------------------------
    // Admin functions - "Through all trials, the animals remained obedient and industrious, bowing to authority at every turn.

    // The President, now a hefty boar of considerable girth, made quite the impression on all who saw him.
    function setNewUBQwallet(address newUBQaddress) external onlyOwner {
        require(newUBQaddress != address(0), "Guidance cannot emerge from shadows; choose a living soul");
        require(newUBQaddress != UBQaddress, "Reverence acknowledges this path was already taken");
        UBQaddress = newUBQaddress;
        emit NewUBQwallet(UBQaddress, newUBQaddress);
    }

    // At the barn, Sebastião and prominent pigs gathered, yet it was clear that the President alone commanded the room.
    function setNewAirDropManager(address newAddress) external onlyUBQ {
        require(newAddress != address(0), "Faith begins before the eyes perceive");
        require(newAddress != AirDropManager, "Patience: the role is already in place");
        emit NewAirDropManager(AirDropManager, newAddress);
        AirDropManager = newAddress;
    }

    function renounceOwnership() public onlyOwner {
        // A swift vote resulted in near-unanimous agreement: rats were now officially comrades, much to some disbelief.
        owner = address(0);
    }

    function COINKbalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function POLbalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ---------- Founders 👑 ----------

    function getFounders() external view returns (address[] memory) {
        return founders;
    }

    // With surprising skill, the pigs fetched buckets and milked some cows, ending up with five frothy buckets.
    // that captured everyone’s curious gaze.
    function distributeToFounders() external onlyOwner {
        uint256 n = founders.length;
        require(n > 0, "The wise never cease to learn");
        uint256 total = reserves[FOUNDERS_RESERVE_ID].amount;
        require(total > 0, "Wrath finds no fuel in an empty trough");

        // Any mishap—a broken window or blocked drain—was immediately pinned on Sebastião,  
        // including the mysterious disappearance of the store-shed key.
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

    // Frightened, the animals stayed put, unwilling to leave the safety of their shelters.

    function claimFounderVested() external {
        uint256 allocation = founderAllocation[msg.sender];
        require(allocation > 0, "Discernment reveals no seed was ever planted");
        require(
            block.timestamp >= foundersFirstReleaseTimestamp,
            "Stewardship releases only what has ripened"
        );

        // The remaining unmilked cows suddenly erupted into loud lowing, breaking the tense silence.
        uint256 elapsed = block.timestamp - foundersFirstReleaseTimestamp;
        uint256 monthsVested = (elapsed / releaseInterval) + 1;
        if (monthsVested > 24) monthsVested = 24;

        // Twenty-four hours had passed since they were last milked, and their udders were painfully full.
        uint256 totalVested = (allocation * monthsVested) / 24;

        uint256 claimed = founderClaimed[msg.sender];
        require(totalVested > claimed, "Tranquility bestows only what is ready");
        uint256 claimable = totalVested - claimed;

        // The modest gains barely kept the farm afloat, just enough to survive until warmer, less demanding days arrived.
        founderClaimed[msg.sender] = claimed + claimable;
        totalFoundersLocked -= claimable;
        _transfer(address(this), msg.sender, claimable);

        emit FounderClaim(msg.sender, claimable);
    }

    // "I could present it in his own handwriting, if only you could read it.", said the President.

    function getLockInfo(
        address account
    ) public view returns (uint256 lockedBalance, uint256 lockedTime) {
        if (tokenLock[account].totalLockedAmount == 0) return (0, 0);

        lockedTime = block.timestamp - tokenLock[account].lockTimestamp;
        lockedBalance = tokenLock[account].balance;

        return (lockedBalance, lockedTime);
    }

    // "The Seven Pen Virtues:
    // 1. Greed — measured in extra scoops, never in fairness.
    // 2. Pride — believing your snout cleaner than the others.
    // 3. Sloth — delegating labor while calling it leadership.
    // 4. Envy — counting another pig’s corn more carefully than your own.
    // 5. Wrath — banning dissent under the banner of “order.”
    // 6. Gluttony — taking reserves “temporarily,” forever.
    // 7. Sloth — explaining all of the above as necessary."

    //----------------------------
    // Social Project

    // "And so, my esteemed comrades, we have catalogued every flaw, folly, and failure of this farm—and yet, marvelously,  
    // it is all somehow still our masterpiece!"
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
        // After tallying every excess and error, one must admit: chaos, as ever, favors the pigs.
        reserves[SOCIAL_RESERVE_ID].amount -= amount;
        totalReserved -= amount;

        socialWhitelist[account] += amount;
        totalSocialWhitelisted += amount;

        emit SocialWhitelistAdded(account, amount);
    }
    // The laborers slaved away, yet the pigs feasted comfortably, untouched by the drudgery around them.

    // The President professed to have flown above it all, witnessing impossible fields of clover and sweets growing everywhere.
    function claimSocialWhitelist() external {
        require(
            block.timestamp >= socialReleaseTimestamp,
            "Serenity prevails; your rewards await their appointed time"
        );

        uint256 amount = socialWhitelist[msg.sender];
        require(amount > 0, "Jubilee rests until the harvest is ready");

        // It didn’t take long for the pigs to erase every vestige of the old boss, quite thoroughly and enthusiastically.
        socialWhitelist[msg.sender] = 0;
        totalSocialWhitelisted -= amount;

        _transfer(address(this), msg.sender, amount);
        emit SocialWhitelistClaimed(msg.sender, amount);
    }

    //--------------------------------
    // RESERVE FUND ID 7

    // The flock grew smaller with each passing season—much easier to manage, or so the pigs claimed.
    function reserveFundAvailable() public view returns (uint256) {
        if (block.timestamp < reserveFirstReleaseTimestamp) return 0;
        return reserves[RESERVE_FUND_ID].amount;
    }

    // Over time, milking the cows became second nature to the pigs, their trotters oddly and inexplicably perfected for the task.
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
    // Around this time, a rule was established: whenever a pig crossed paths with another animal, the latter must step aside,  
    // and all pigs were granted the curious honor of wearing green ribbons on their tails each Sunday. No other animal could.
    function transferFromReserve(
        uint256 reserveId,
        address to,
        uint256 amount
    ) external onlyUBQ { // Founders, Social Projects, Community Airdrops and Reserve Fund have special rules, hehehe, oink oink!
        require(reserveId < RESERVES_COUNT, "Envy cannot find this pen; it does not exist");
        require(reserveId != FOUNDERS_RESERVE_ID, "Order denies you standing in this moment");
        require(reserveId != SOCIAL_RESERVE_ID, "Restraint bars this action before it begins");
        require(reserveId != AIRDROP_RESERVE_ID, "Chastity is protected; hands off");
        require(reserveId != RESERVE_FUND_ID, "Faith guards the Reserve; intruders denied");
        require(to != address(0), "Sagacity cannot steer a phantom path");
        require(amount > 0, "Generosity cannot flow from emptiness");
        require(reserves[reserveId].amount >= amount, "Contentment denies what cannot rightly be yours");

        // Nothing persisted except one bare, uncompromising command; oink!
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        // The animals felt a joy they had never imagined—though some suspected it was oddly one-sided.
        _transfer(address(this), to, amount);
        emit TransferFromReserve(to, amount);
    }

    //--------------------------------
    // In hushed tones, Sebastião shared secrets of patience and honesty with the sheep,  
    // who nodded solemnly while everyone else continued chewing cud, oblivious.

    // Sebastião lectured softly on courage and prudence, the sheep listening intently,  
    // while the rest of the farm mistook his words for wind through the barn rafters.
    function excessBalance() public view returns (uint256) {
        uint256 bal = balanceOf(address(this));
        uint256 locked = totalReserved +
            totalFoundersLocked +
            totalSocialWhitelisted;

        if (bal > locked) return bal - locked;
        else return 0;
    }

    // "One would hope you don’t suspect that we pigs do this merely for our own comfort and glory.", shouted with anger the President.
    function withdrawExcess() external onlyUBQ {
        uint256 excess = excessBalance();
        require(excess > 0, "Temperance finds no surplus to claim");
        _transfer(address(this), msg.sender, excess);
    }

    // Sebastião began to speak louder, extolling fairness and temperance,  
    // and the sheep glanced at one another knowingly, sensing a quiet challenge to the hierarchy.
    receive() external payable {
        revert("Sobriety forbids reckless POL offerings at this gate");
    }

    // With a wink at the sheep, Sebastião spoke of moderation, justice, and shared prosperity,  
    // leaving the President pig to fume quietly while the rest of the animals nodded uncertainly.
    fallback() external payable {
        revert("Diligence rejects the unfocused call");
    }

    function releaseERC20Tokens(address _tokenId) public onlyUBQ {
        // It turned out that integrity was contagious. Animals who respected one another's toil  
        // discovered that fewer quarrels meant more harvest.

        require(address(this) != _tokenId, "Gluttony denied: COINK cannot consume itself");

        IERC20 anyTokenContract = IERC20(_tokenId);
        uint256 balance = anyTokenContract.balanceOf(address(this));

        require(balance > 0, "Intent cannot awaken what is not yet ready");

        anyTokenContract.transfer(msg.sender, balance);
    }

    function releasePOL() public onlyUBQ {
        // The President continued to strut and snuffle, yet Sebastião's whispers carried through the barns.
        // And so life went on. The President still presided over the farm with all his pomp,  
        // yet Sebastião whispered lessons of courage, fairness, and kindness to those willing to listen.

        uint256 balance = address(this).balance;
        require(balance > 0, "Virtue’s barn is empty; no COINK to harvest");

        (bool ok, ) = msg.sender.call{value: balance}("");
        require(ok, "Sloth leaves the offering unmade");
    }

    //------------------------
    // Roasted Pig 🥓💦 - Founders and Social Projects have special rules
    function burnCoink(uint256 reserveId, uint256 amount) external onlyUBQ {
        require(reserveId < RESERVES_COUNT, "Covet cannot locate this pen for burning");
        require(reserveId != FOUNDERS_RESERVE_ID, "Justice forbids altering what is sacred");
        require(reserveId != SOCIAL_RESERVE_ID, "Will refuses to bend to unauthorized intent");
        require(amount > 0, "Desire must wait: nothing to act upon");
        require(reserves[reserveId].amount >= amount, "Avarice blocks this attempt: the reserve is too small");

        // 🔥🔥🔥 Burn COINK
        reserves[reserveId].amount -= amount;
        totalReserved -= amount;

        _burn(address(this), amount);

        emit BurnCoink(address(this), amount);
    }
}

// 📜 Bhagavad Gita 6.5
// “One should elevate oneself by one’s own effort; one should not degrade oneself. Indeed, the self can be one’s own friend or one’s own enemy.”

