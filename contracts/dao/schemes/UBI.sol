pragma solidity 0.5.4;

import "@daostack/arc/contracts/controller/Avatar.sol";
import "@daostack/arc/contracts/controller/ControllerInterface.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../identity/Identity.sol";
import "../../identity/IdentityGuard.sol";

import "../../token/GoodDollar.sol";

import "./ActivePeriod.sol";
import "./FeelessScheme.sol";

/* @title Base contract template for UBI scheme 
 */
contract AbstractUBI is ActivePeriod, FeelessScheme {
    using SafeMath for uint256;

    uint256 initialReserve;

    uint256 public claimDistribution;

    struct Day {
        mapping (address => bool) hasClaimed;
        uint256 amountOfClaimers;
        uint256 claimAmount;
    }

    mapping (uint => Day) claimDay;

    mapping (address => uint) public lastClaimed;

    uint public currentDay;
    uint public lastCalc;

    event UBIStarted(uint256 balance, uint time);
    event UBIClaimed(address indexed claimer, uint256 amount);
    event UBIEnded(uint256 claimers, uint256 claimamount);
    /**
     * @dev Constructor. Checks if avatar is a zero address
     * and if periodEnd variable is after periodStart.
     * @param _avatar the avatar contract
     * @param _periodStart period from when the contract is able to start
     * @param _periodEnd period from when the contract is able to end
     */
    constructor(
        Avatar _avatar,
        Identity _identity,
        uint256 _initialReserve,
        uint _periodStart,
        uint _periodEnd
    )
        public
        ActivePeriod(_periodStart, _periodEnd)
        FeelessScheme(_identity, _avatar)
    {
        initialReserve = _initialReserve;
    }

    /**
     * @dev function that returns an uint256 that
     * represents the amount each claimer can claim.
     * @param reserve the account balance to calculate from
     * @return The distribution for each claimer
     */
    function distributionFormula(uint256 reserve, address user) internal returns(uint256);

    /* @dev function that gets the amount of people who claimed on the given day
     * @param day the day to get claimer count from, with 0 being the starting day
     * @returns an integer indicating the amount of people who claimed that day
     */
    function getClaimerCount(uint day) public view returns (uint256) {
        return claimDay[day].amountOfClaimers;
    }

    /* @dev function that gets the amount that was claimed on the given day
     * @param day the day to get claimer count from, with 0 being the starting day
     * @returns an integer indicating the amount that has been claimed on the given day
     */
    function getClaimAmount(uint day) public view returns (uint256) {
        return claimDay[day].claimAmount;
    }

    /* @dev function that gets count of claimers and amount claimed for the most recent
     * day where claiming transpired.
     * @returns the amount of claimers and the amount claimed. 
     */
    function getDailyStats() public view returns (uint256 count, uint256 amount) {
        return (getClaimerCount(currentDay), getClaimAmount(currentDay));
    }

    /* @dev Function that commences distribution period on contract.
     * Can only be called after periodStart and before periodEnd and
     * can only be done once. The reserve is sent
     * to this contract to allow claimers to claim from said reserve.
     * The claim distribution is then calculated and true is returned
     * to indicate that claiming can be done.
     */
    function start() public onlyRegistered {
        super.start();
        addRights();

        currentDay = 0;
        lastCalc = now;

        // Transfer the fee reserve to this contract
        DAOToken token = avatar.nativeToken();

        if(initialReserve > 0) {
            require(initialReserve <= token.balanceOf(address(avatar)), "Not enough funds to start");

            controller.genericCall(
                address(token),
                abi.encodeWithSignature("transfer(address,uint256)", address(this), initialReserve),
                avatar,
                0);
        }
        emit UBIStarted(token.balanceOf(address(this)), now);
    }

    /**
     * @dev Function that ends the claiming period. Can only be done if
     * Contract has been started and periodEnd is passed.
     * Sends the remaining funds on contract back to the avatar contract
     * address
     */
    function end(Avatar /*_avatar*/) public requirePeriodEnd {

        DAOToken token = avatar.nativeToken();

        uint256 remainingReserve = token.balanceOf(address(this));

        if (remainingReserve > 0) {
            token.transfer(address(avatar), remainingReserve);
        }

        removeRights();
        super.end(avatar);
    }

    /* @dev Function that claims UBI to message sender.
     * Each claimer can only claim once per UBI contract
     */
    function claim() 
        public 
        requireActive
        onlyWhitelisted
        onlyAddedBefore(periodStart)
        returns(bool)
    {
        require(!claimDay[currentDay].hasClaimed[msg.sender], "has already claimed");

        GoodDollar token = GoodDollar(address(avatar.nativeToken()));

        claimDay[currentDay].hasClaimed[msg.sender] = true;
        token.transfer(msg.sender, claimDistribution);

        claimDay[currentDay].amountOfClaimers = claimDay[currentDay].amountOfClaimers.add(1);
        claimDay[currentDay].claimAmount = claimDay[currentDay].claimAmount.add(claimDistribution);

        lastClaimed[msg.sender] = now;
        
        emit UBIClaimed(msg.sender, claimDistribution);
        return true;
    }
}

/* @title UBI scheme contract responsible for calculating distribution
 * and performing the distribution itself
 */
contract UBI is AbstractUBI {

    /* @dev Constructor. Checks if avatar is a zero address
     * and if periodEnd variable is after periodStart.
     * @param _avatar the avatar contract
     * @param _identity the identity contract
     * @param _periodStart period from when the contract is able to start
     * @param _periodEnd period from when the contract is able to end
     */
    constructor(
        Avatar _avatar,
        Identity _identity,
        uint256 _initialReserve,
        uint _periodStart,
        uint _periodEnd
    )
        public
        AbstractUBI(_avatar, _identity, _initialReserve, _periodStart, _periodEnd)
    {}

    /* @dev function that returns an uint256 that
     * represents the amount each claimer can claim.
     * @param reserve the account balance to calculate from
     * @return The reserve divided by the amount of registered claimers
     */
    function distributionFormula(uint256 reserve, address /*user*/) internal returns(uint256) {
        uint claimers = identity.getWhitelistedCount();
        return reserve.div(claimers);
    }

    /* @dev starts scheme and calculates dispersion of UBI
     * @returns a bool indicating if scheme has started
     */
    function start() public {
        super.start();

        DAOToken token = avatar.nativeToken();
        claimDistribution = distributionFormula(token.balanceOf(address(this)), address(0));

    }    
}
