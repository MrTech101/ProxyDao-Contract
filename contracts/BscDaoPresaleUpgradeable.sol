/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title The BscDaoPresaleUpgradeable
 * @dev The contract is upgradeable through EIP1967 pattern
 * @author BSCDAO
 * @notice Performs BscDao presale & claim
 */
contract BscDaoPresaleUpgradeable is Initializable, OwnableUpgradeable {
    /// @dev Receive BNB
    receive() external payable {}

    /// @dev The presale info
    struct PreSaleInfo {
        // The minimum bscDao allocation
        uint256 minAllocation;
        // The maximum bscDao allocation
        uint256 maxAllocation;
        // The purchase cap
        uint256 purchaseCap;
    }

    /// @dev The affiliate info
    struct AffiliateInfo {
        // The total number of refered user
        uint256 totalReferedUsers;
        // The earned BNB
        uint256 earnedBNB;
    }

    /// @notice The presale info
    PreSaleInfo public preSaleInfo;

    /// @notice The contract instance of BSCDAO token
    IERC20 public bscDao;

    /// @notice The price numerator of bsc dao
    uint256 public constant PRICE_NUMERATOR = 1000000;

    /// @notice The percentage of BSCDAO affiliates
    uint256 public affiliatePercentage;

    /// @notice The price of bsc dao token
    uint256 public bscDaoPrice;

    /// @notice The raised amount BNB
    uint256 public raisedBnb;

    /// @notice The number of total users participated
    uint256 public totalUsersParticipated;

    /// @notice The identifier for public sale
    bool public isPublicSale;

    /// @notice The identifier to check if sale ends
    bool public isSaleEnd;

    /// @notice The list of bsc dao user allocation
    mapping(address => uint256) public bscDaoUserAllocation;

    /// @notice The list of user purchases
    mapping(address => uint256) public userPurchases;

    /// @notice The affiliate details
    mapping(address => AffiliateInfo) public affiliates;

    /**
     * @notice Initliazation of BscDaoPresaleUpgradeable
     * @param _bscDao The contract address of BSCDAO token
     * @param _bscDaoPrice The price per BNB of BSCDAO
     * @param _affiliatePercentage The percentage of affiliate
     * @param _minAllocation The minimum amount of user allocation
     * @param _maxAllocation The maximum amount of user allocation
     * @param _purchaseCap The purchase cap
     */
    function __BscDaoPresaleUpgradeable_init(
        address _bscDao,
        uint256 _bscDaoPrice,
        uint256 _affiliatePercentage,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap
    ) external initializer {
        __Ownable_init();
        __BscDaoPresaleUpgradeable_init_unchained(
            _bscDao,
            _bscDaoPrice,
            _affiliatePercentage,
            _minAllocation,
            _maxAllocation,
            _purchaseCap
        );
    }

    /**
     * @notice Sets initial state of BSCDAO presale contract
     * @param _bscDao The contract address of BSCDAO token
     * @param _bscDaoPrice The price per BNB of BSCDAO
     * @param _affiliatePercentage The percentage of affiliate
     * @param _minAllocation The minimum amount of user allocation
     * @param _maxAllocation The maximum amount of user allocation
     * @param _purchaseCap The purchase cap
     */
    function __BscDaoPresaleUpgradeable_init_unchained(
        address _bscDao,
        uint256 _bscDaoPrice,
        uint256 _affiliatePercentage,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap
    ) internal initializer {
        require(
            _bscDao != address(0) &&
                _minAllocation > 0 &&
                _maxAllocation > _minAllocation &&
                _purchaseCap > _maxAllocation,
            "Invalid Args"
        );

        bscDao = IERC20(_bscDao);
        bscDaoPrice = _bscDaoPrice;
        affiliatePercentage = _affiliatePercentage;

        // set presale details
        preSaleInfo = PreSaleInfo({
            minAllocation: _minAllocation,
            maxAllocation: _maxAllocation,
            purchaseCap: _purchaseCap
        });
    }

    /**
     * @notice Sets affiliate percentage
     * @param _affiliatePercentage The percentage of affiliate
     */
    function setAffiliatePercentage(uint256 _affiliatePercentage)
        external
        onlyOwner
    {
        affiliatePercentage = _affiliatePercentage;
    }

    /**
     * @notice Switch sale flag of BSCDAO
     * @dev Call by current owner of BSCDAO presale
     * @param saleFlag The status of sale flag
     */
    function switchSalePhase(bool saleFlag) external onlyOwner {
        isPublicSale = saleFlag;
    }

    /**
     * @notice Sets BSCDAO users private sale allocations
     * @dev Call by current owner of BSCDAO presale
     * @param users The list of private sale users
     * @param tokens The list of user BSCDAO allocations
     */
    function setBscDaoUsersAllocation(
        address[] memory users,
        uint256[] memory tokens
    ) external onlyOwner {
        uint8 usersCount = uint8(users.length);
        require(usersCount > 0 && usersCount == tokens.length);
        for (uint8 j = 0; j < usersCount; j++) {
            require(users[j] != address(0) && tokens[j] > 0, "Mismatch Args");
            bscDaoUserAllocation[users[j]] = tokens[j];
        }
    }

    /**
     * @notice Update bsc dao price
     * @dev Call by current owner of BSCDAO presale
     * @param _bscDaoPrice The price of bsc dao token
     */
    function updateBscDaoPrice(uint256 _bscDaoPrice) external onlyOwner {
        bscDaoPrice = _bscDaoPrice;
    }

    /**
     * @notice Update BSC Dao token contract instance
     * @dev Call by current owner of BSCDAO presale
     * @param _bscDao The contract address of BSCDAO token
     */
    function updateBscDao(address _bscDao) external onlyOwner {
        bscDao = IERC20(_bscDao);
    }

    /**
     * @notice Update presale info
     * @dev Call by current owner of BSCDAO presale
     * @param minAllocation The amount of minimum allocation
     * @param maxAllocation The amount of maximum allocation
     * @param purchaseCap The purchase cap
     */
    function updatePreSaleInfo(
        uint256 minAllocation,
        uint256 maxAllocation,
        uint256 purchaseCap
    ) external onlyOwner {
        require(
            minAllocation > 0 &&
                maxAllocation > minAllocation &&
                purchaseCap > maxAllocation,
            "Invalid Sale Info"
        );
        preSaleInfo = PreSaleInfo(minAllocation, maxAllocation, purchaseCap);
    }

    /**
     * @notice Sets sale ends
     * @dev Call by current owner of BSCDAO presale
     * @param saleEndFlag The status of sale ends flag
     */
    function setSaleEnds(bool saleEndFlag) external onlyOwner {
        isSaleEnd = saleEndFlag;
    }

    /**
     * @notice buy BSCDAO token with BNB
     * @param amount The amount of bnb to purchase
     */
    function buy(address affiliate, uint256 amount) external payable {
        // verify the purchase
        _verifyPurchase(amount);

        require(amount == msg.value, "Invalid Value");
        require(!isSaleEnd, "Sale Ends");

        require(
            preSaleInfo.purchaseCap >= raisedBnb + amount,
            "Purchase Cap Reached"
        );

        raisedBnb += amount;

        if (userPurchases[_msgSender()] == 0) {
            totalUsersParticipated++;
        }

        if (affiliate != address(0)) {
            affiliates[affiliate].totalReferedUsers++;
            affiliates[affiliate].earnedBNB +=
                (amount * affiliatePercentage) /
                1e8;
        }

        userPurchases[_msgSender()] += amount;
    }

    /**
     * @notice Claim BSC DAO
     * @dev Countered Error when invalid attempt or sale not ends
     */
    function claimBscDao() external {
        uint256 purchaseAmount = userPurchases[_msgSender()];
        require(purchaseAmount > 0, "Invalid Attempt");
        require(isSaleEnd, "Sale Not Ends Yet");

        // reset to 0
        userPurchases[_msgSender()] = 0;

        uint256 transferableBscDao = _convertBnbToBscDao(purchaseAmount);
        bscDao.transfer(_msgSender(), transferableBscDao);
    }

    /**
     * @notice Claim affiliate earning
     * @dev Throws error when no earned value found
     */
    function claimAffiliateEarning() external {
        uint256 earnedBnb = affiliates[_msgSender()].earnedBNB;
        require(earnedBnb > 0, "No Earned Value");
        require(isSaleEnd, "Sale Not Ends Yet");

        uint256 earnedBscDao = _convertBnbToBscDao(earnedBnb);
        affiliates[_msgSender()].earnedBNB = 0;
        bscDao.transfer(_msgSender(), earnedBscDao);
    }

    /**
     * @notice Withdraw raised BNB
     * @dev Throw error when withdraw failed &
     * Call by current owner of BSCDAO presale
     * @param withdrawableAddress The account of withdrawable
     * @param value The value to be withdraw
     */
    function withdraw(address withdrawableAddress, uint256 value)
        external
        onlyOwner
    {
        require(
            withdrawableAddress != address(0),
            "Invalid Withdrawable Address"
        );
        require(address(this).balance >= value, "Invalid Value");
        (bool success, ) = withdrawableAddress.call{value: value}("");
        require(success, "Withdraw Failed");
    }

    /**
     * @notice Rescue Any Token
     * @dev Call by current owner of BSCDAO presale
     * @param withdrawableAddress The account of withdrawable
     * @param token The instance of ERC20 token
     * @param amount The token amount to withdraw
     */
    function rescueToken(
        address withdrawableAddress,
        IERC20 token,
        uint256 amount
    ) external onlyOwner {
        require(
            withdrawableAddress != address(0),
            "Invalid Withdrawable Address"
        );
        token.transfer(withdrawableAddress, amount);
    }

    /**
     * @notice Verify the purchases
     * @dev Throws error when purchases verification failed
     * @param amount The amount to buy
     */
    function _verifyPurchase(uint256 amount) internal view {
        uint256 maxAllocation = isPublicSale
            ? preSaleInfo.maxAllocation
            : bscDaoUserAllocation[_msgSender()];
        require(
            amount >= preSaleInfo.minAllocation &&
                amount <= maxAllocation &&
                userPurchases[_msgSender()] + amount <= maxAllocation,
            "Buy Failed"
        );
    }

    /**
     * @notice Convert BNB to BSC DAO token & Returns converted BSCDAO's
     * @param amount The amount of BNB
     * @return bscDaos The amount of BSCDAO's
     */
    function _convertBnbToBscDao(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * PRICE_NUMERATOR) / (bscDaoPrice * 1e9);
    }
}
