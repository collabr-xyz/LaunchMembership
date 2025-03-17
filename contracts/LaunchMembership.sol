// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ClubMembership
 * @dev A contract for club membership NFTs with role-based permissions
 */
contract LaunchMembershipV3 is ERC721Base, PermissionsEnumerable {
    // Club information
    string public clubName;
    string public clubDescription;
    string public clubImageURI;
    uint256 public membershipLimit;
    uint256 public membershipPrice;
    address public clubCreator;
    uint256 public totalMembers;
    IERC20 public paymentToken; // Reference to the $GROW token
    
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    // Events
    event MembershipPurchased(address indexed member, uint256 tokenId);
    event ClubInfoUpdated(string newName, string newDescription, string newImageURI);
    event MembershipPriceUpdated(uint256 newPrice);
    event MembershipLimitUpdated(uint256 newLimit);
    event PaymentTokenUpdated(address newToken);
    
    /**
     * @dev Constructor to initialize the club membership contract
     */
    constructor(
        string memory _clubName,
        string memory _clubDescription,
        string memory _clubImageURI,
        uint256 _membershipLimit,
        uint256 _membershipPrice,
        string memory _nftName,
        string memory _nftSymbol,
        address _paymentToken // Address of the $GROW token
    ) 
        ERC721Base(
            msg.sender,
            _nftName,
            _nftSymbol,
            msg.sender,  // Setting royalty recipient to msg.sender but with 0 bps
            0            // Setting royalty bps to 0 to remove royalties
        ) 
    {
        clubName = _clubName;
        clubDescription = _clubDescription;
        clubImageURI = _clubImageURI;
        membershipLimit = _membershipLimit;
        membershipPrice = _membershipPrice;
        clubCreator = msg.sender;
        totalMembers = 0;
        paymentToken = IERC20(_paymentToken); // Initialize the payment token
        
        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev Purchase a membership NFT using $GROW tokens
     */
    function purchaseMembership() external returns (uint256) {
        require(totalMembers < membershipLimit, "Membership limit reached");
        
        // Transfer $GROW tokens from buyer to contract
        require(paymentToken.transferFrom(msg.sender, address(this), membershipPrice), 
                "Token transfer failed");
        
        // Mint the membership NFT
        uint256 tokenId = totalMembers + 1;
        _safeMint(msg.sender, tokenId);
        totalMembers += 1;
        
        emit MembershipPurchased(msg.sender, tokenId);
        return tokenId;
    }
    
    /**
     * @dev Check if an address is a member of the club
     */
    function isMember(address _address) public view returns (bool) {
        return balanceOf(_address) > 0;
    }
    
    /**
     * @dev Update club information (admin only)
     */
    function updateClubInfo(
        string memory _newName,
        string memory _newDescription,
        string memory _newImageURI
    ) external onlyRole(ADMIN_ROLE) {
        clubName = _newName;
        clubDescription = _newDescription;
        clubImageURI = _newImageURI;
        
        emit ClubInfoUpdated(_newName, _newDescription, _newImageURI);
    }
    
    /**
     * @dev Update membership price (admin only)
     */
    function updateMembershipPrice(uint256 _newPrice) external onlyRole(ADMIN_ROLE) {
        membershipPrice = _newPrice;
        emit MembershipPriceUpdated(_newPrice);
    }
    
    /**
     * @dev Update membership limit (admin only)
     */
    function updateMembershipLimit(uint256 _newLimit) external onlyRole(ADMIN_ROLE) {
        require(_newLimit >= totalMembers, "New limit cannot be less than current members");
        membershipLimit = _newLimit;
        emit MembershipLimitUpdated(_newLimit);
    }
    
    /**
     * @dev Add a moderator (admin only)
     */
    function addModerator(address _moderator) external onlyRole(ADMIN_ROLE) {
        grantRole(MODERATOR_ROLE, _moderator);
    }
    
    /**
     * @dev Remove a moderator (admin only)
     */
    function removeModerator(address _moderator) external onlyRole(ADMIN_ROLE) {
        revokeRole(MODERATOR_ROLE, _moderator);
    }
    
    /**
     * @dev Update payment token (admin only)
     */
    function updatePaymentToken(address _newToken) external onlyRole(ADMIN_ROLE) {
        paymentToken = IERC20(_newToken);
        emit PaymentTokenUpdated(_newToken);
    }
    
    /**
     * @dev Withdraw ERC20 tokens from the contract (admin only)
     */
    function withdrawTokens() external onlyRole(ADMIN_ROLE) {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(paymentToken.transfer(clubCreator, balance), "Token transfer failed");
    }
    
    /**
     * @dev Withdraw any ETH that might have been sent to the contract (admin only)
     * This is kept for safety, in case ETH is accidentally sent to the contract
     */
    function withdrawETH() external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(clubCreator).transfer(balance);
    }
}