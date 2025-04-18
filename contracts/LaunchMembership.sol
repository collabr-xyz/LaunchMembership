// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Added Base64 for encoding

/**
 * @title LaunchMembershipV7
 * @dev An enhanced contract for club membership NFTs with better validation and logging
 */
contract LaunchMembershipV7 is ERC721Base, PermissionsEnumerable {
    // Club information
    string public clubName;
    string public clubDescription;
    string public clubImageURI;
    uint256 public membershipLimit;
    uint256 public membershipPrice;
    address public clubCreator;
    uint256 public totalMembers;
    IERC20 public paymentToken; // Reference to the $GROW token
    
    // Token storage related variables
    uint256 public totalStoredTokens;
    
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    
    // Events
    event MembershipPurchased(address indexed member, uint256 tokenId, uint256 price);
    event ClubInfoUpdated(string newName, string newDescription, string newImageURI);
    event MembershipPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event MembershipLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event PaymentTokenUpdated(address oldToken, address newToken);
    event TokensWithdrawn(uint256 amount, address to);
    event ETHWithdrawn(uint256 amount, address to);
    event TokensStored(address indexed member, uint256 amount);
    event TokensClaimed(uint256 amount, address to);
    
    /**
     * @dev Constructor to initialize the club membership contract
     * @param _membershipPrice IMPORTANT: Must be in token units with 18 decimals (e.g. 2 tokens = 2000000000000000000)
     */
    constructor(
        string memory _clubName,
        string memory _clubDescription,
        string memory _clubImageURI,
        uint256 _membershipLimit,
        uint256 _membershipPrice,
        string memory _nftName,
        string memory _nftSymbol,
        address _paymentToken
    ) 
        ERC721Base(
            msg.sender,
            _nftName,
            _nftSymbol,
            msg.sender,
            0
        ) 
    {
        require(_membershipPrice > 0, "Membership price must be greater than 0");
        require(_membershipLimit > 0, "Membership limit must be greater than 0");
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        
        clubName = _clubName;
        clubDescription = _clubDescription;
        clubImageURI = _clubImageURI;
        membershipLimit = _membershipLimit;
        membershipPrice = _membershipPrice;
        clubCreator = msg.sender;
        totalMembers = 0;
        totalStoredTokens = 0;
        paymentToken = IERC20(_paymentToken);
        
        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        
        // Log initial price for transparency
        emit MembershipPriceUpdated(0, _membershipPrice);
    }
    
    /**
     * @dev Helper function to convert uint256 to string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    /**
     * @dev Override tokenURI to generate on-chain metadata with clubImageURI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        
        // Generate JSON metadata with clubImageURI as the image
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name":"', clubName, ' Membership #', toString(tokenId), '",',
                            '"description":"', clubDescription, '",',
                            '"image":"', clubImageURI, '",',
                            '"attributes":[{"trait_type":"Club","value":"', clubName, '"}]}'
                        )
                    )
                )
            )
        ));
    }
    
    /**
     * @dev Purchase a membership NFT using payment tokens
     * @return The ID of the minted NFT
     */
    function purchaseMembership() external returns (uint256) {
        require(membershipPrice > 0, "Membership price not set");
        require(totalMembers < membershipLimit, "Membership limit reached");
        require(balanceOf(msg.sender) == 0, "Already a member");
        
        // Transfer tokens from buyer to contract
        bool transferSuccess = paymentToken.transferFrom(msg.sender, address(this), membershipPrice);
        require(transferSuccess, "Token transfer failed");
        
        // Mint the membership NFT
        uint256 tokenId = totalMembers + 1;
        _safeMint(msg.sender, tokenId);
        totalMembers += 1;
        
        // Record the membership payment as stored tokens
        totalStoredTokens += membershipPrice;
        
        emit MembershipPurchased(msg.sender, tokenId, membershipPrice);
        emit TokensStored(msg.sender, membershipPrice);
        
        return tokenId;
    }
    
    /**
     * @dev Check if an address is a member of the club
     */
    function isMember(address _address) public view returns (bool) {
        return balanceOf(_address) > 0;
    }
    
    /**
     * @dev Allow the club creator to claim the stored tokens
     * @param _amount The amount of tokens to claim
     */
    function claimTokens(uint256 _amount) external onlyRole(ADMIN_ROLE) {
        require(_amount > 0, "Must claim more than 0 tokens");
        require(_amount <= totalStoredTokens, "Not enough stored tokens");
        
        // Update stored tokens amount
        totalStoredTokens -= _amount;
        
        // Transfer tokens to the club creator
        bool transferSuccess = paymentToken.transfer(clubCreator, _amount);
        require(transferSuccess, "Token transfer failed");
        
        emit TokensClaimed(_amount, clubCreator);
    }
    
    /**
     * @dev Get the amount of tokens stored in the contract
     */
    function getStoredTokens() external view returns (uint256) {
        return totalStoredTokens;
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
     * @param _newPrice IMPORTANT: Must be in token units with 18 decimals (e.g. 2 tokens = 2000000000000000000)
     */
    function updateMembershipPrice(uint256 _newPrice) external onlyRole(ADMIN_ROLE) {
        require(_newPrice > 0, "New price must be greater than 0");
        uint256 oldPrice = membershipPrice;
        membershipPrice = _newPrice;
        emit MembershipPriceUpdated(oldPrice, _newPrice);
    }
    
    /**
     * @dev Update membership limit (admin only)
     */
    function updateMembershipLimit(uint256 _newLimit) external onlyRole(ADMIN_ROLE) {
        require(_newLimit >= totalMembers, "New limit cannot be less than current members");
        uint256 oldLimit = membershipLimit;
        membershipLimit = _newLimit;
        emit MembershipLimitUpdated(oldLimit, _newLimit);
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
        require(_newToken != address(0), "New token cannot be zero address");
        address oldToken = address(paymentToken);
        paymentToken = IERC20(_newToken);
        emit PaymentTokenUpdated(oldToken, _newToken);
    }
    
    /**
     * @dev Withdraw any ETH that might have been sent to the contract (admin only)
     */
    function withdrawETH() external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(clubCreator).transfer(balance);
        emit ETHWithdrawn(balance, clubCreator);
    }
}