//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

import "./IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Presale is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;

    // @dev The PreSalaInfo
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
    // The token address tobe sold
    IERC20 public bscDao;

    // How many token units a buyer gets per wei
    uint256 public bscDaoPrice;

    //set wallet address that is going to recieve the bnb when buy function works 
    address wallet;

    // Total cap
    uint256 public Cap;

    // Amount of wei raised
    uint256 public raisedBnb;

    /// @notice The price numerator of bsc dao
    uint256 public constant PRICE_NUMERATOR = 1000000;

    /// @notice The percentage of BSCDAO affiliates
    uint256 public affiliatePercentage;

    /// @notice The presale info
    PreSaleInfo public preSaleInfo;

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

    uint internal tokenValue;
    // initilizer function for the presale contract
     function _upgradablePreSale(
        address _token,
        uint256 _rate,
        uint256 _affiliatePercentage,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap
    ) external initializer {
         __Ownable_init();
        _upgradablePreSale_unchained(
            _token,
            _rate,
            _affiliatePercentage,
            _minAllocation,
            _maxAllocation,
            _purchaseCap
        );
    }

    function _upgradablePreSale_unchained(
        address _token,
        uint256 _rate,
        uint256 _affiliatePercentage,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        uint256 _purchaseCap
    ) internal initializer {
      require(
            _token != address(0) &&
                _minAllocation > 0 &&
                _maxAllocation > _minAllocation &&
                _purchaseCap > _maxAllocation,
            "Invalid Args"
        );

        bscDao = IERC20(_token);
        bscDaoPrice = _rate;
        affiliatePercentage = _affiliatePercentage;

        // set presale details
        preSaleInfo = PreSaleInfo({
            minAllocation: _minAllocation,
            maxAllocation: _maxAllocation,
            purchaseCap: _purchaseCap
        });
    }
   
    function buyTokens(address _beneficiary) public payable {
         require(raisedBnb <= Cap , "Cap price reached , No more Coins To sell");
         require(!isSaleEnd, "Sale Ends");

        // getting the value of purchasing token
        uint256 weiAmount = msg.value;
        // update raised bnb 
        raisedBnb = raisedBnb.add(weiAmount);

        // condition check user Purchase and affiliate
         if (userPurchases[_msgSender()] == 0) {
            totalUsersParticipated++;
        }

        if (_beneficiary != address(0)) {
            affiliates[_beneficiary].totalReferedUsers++;
            affiliates[_beneficiary].earnedBNB +=
                (weiAmount * affiliatePercentage) /
                1e8;
        }
        // update userPurchases
        userPurchases[_msgSender()] += weiAmount;
        // check if condition matches for _preValidatePurchase
        _preValidatePurchase(_beneficiary, weiAmount);
        // calculate token amount to be created
        tokenValue = weiAmount/bscDaoPrice * 1e18;
        _updatePurchasingState(_beneficiary, weiAmount);
        
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

    // function set total capital to be sold 
    function setCap(uint256 _cap) external onlyOwner{
        Cap = _cap;
    }

    // this funciton is for setAffiliatePercentage
    function setAffiliatePercentage(uint256 _affiliatePercentage)
        external
        onlyOwner
    {
        affiliatePercentage = _affiliatePercentage;
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
     * @notice Switch sale flag of BSCDAO
     * @dev Call by current owner of BSCDAO presale
     * @param saleFlag The status of sale flag
     */
    function switchSalePhase(bool saleFlag) external onlyOwner {
        isPublicSale = saleFlag;
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
     * @notice Claim BSC DAO
     * @dev Countered Error when invalid attempt or sale not ends
     */
    function claimBscDao(address _beneficiary) external {
        require(isSaleEnd, "Sale Not Ends Yet");
       _processPurchase(_beneficiary, tokenValue);
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

    /**
     * @notice Rescue Any Token
     * @dev Call by current owner of BSCDAO presale
     * @param withdrawableAddress The account of withdrawable
     * @param token The instance of ERC20 token
     * @param amount The token amount to withdraw
     */
    function rescueToken(
        IERC20 token,
        address withdrawableAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            withdrawableAddress != address(0),
            "Invalid Withdrawable Address"
        );
        token.transfer(withdrawableAddress, amount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
    {
        require(_beneficiary != address(0) , "invalid address");
        require(_weiAmount != 0,"please input some value in price");
        require(raisedBnb.add(_weiAmount) <= Cap ,"cap price reached");
        require(_weiAmount >= preSaleInfo.minAllocation , "Buy Failed , min allocation not met");
        require(_weiAmount <= preSaleInfo.maxAllocation , "Buy Failed , u excided the max allocation");
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        bscDao.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {   
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
        internal
    {
        // optional override
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}