// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Importing LaunchMembership.sol which contains the LaunchMembershipV5 contract
import "./LaunchMembership.sol";

/**
 * @title MembershipFactory
 * @dev Factory contract to deploy new membership contracts
 */
contract MembershipFactoryV2 {
    // Mapping to track the last contract deployed by each creator
    mapping(address => address) public lastDeployedContract;
    
    // Array to store all deployed contracts
    address[] public deployedContracts;
    
    // Event for new contract deployment
    event ContractDeployed(
        address indexed creator, 
        address contractAddress,
        string clubName,
        uint256 membershipPrice,
        uint256 membershipLimit
    );
    
    /**
     * @dev Deploy a new membership contract with all parameters properly set
     * @param _membershipPrice IMPORTANT: Must be in token units with 18 decimals (e.g. 2 tokens = 2000000000000000000)
     */
    function deployMembershipContract(
        string memory _clubName,
        string memory _clubDescription,
        string memory _clubImageURI,
        uint256 _membershipLimit,
        uint256 _membershipPrice,
        string memory _nftName,
        string memory _nftSymbol,
        address _paymentToken
    ) external returns (address) {
        // Validate input parameters
        require(_membershipPrice > 0, "Membership price must be greater than 0");
        require(_membershipLimit > 0, "Membership limit must be greater than 0");
        require(_paymentToken != address(0), "Payment token cannot be zero address");
        
        // Deploy a new LaunchMembershipV5 contract
        LaunchMembershipV5 newContract = new LaunchMembershipV5(
            _clubName,
            _clubDescription,
            _clubImageURI,
            _membershipLimit,
            _membershipPrice,
            _nftName,
            _nftSymbol,
            _paymentToken
        );
        
        // Store the contract address
        address contractAddress = address(newContract);
        lastDeployedContract[msg.sender] = contractAddress;
        deployedContracts.push(contractAddress);
        
        // Emit event
        emit ContractDeployed(
            msg.sender, 
            contractAddress, 
            _clubName, 
            _membershipPrice, 
            _membershipLimit
        );
        
        return contractAddress;
    }
    
    /**
     * @dev Get the last contract deployed by a creator
     */
    function getLastDeployedContract(address _creator) external view returns (address) {
        return lastDeployedContract[_creator];
    }
    
    /**
     * @dev Get the total number of deployed contracts
     */
    function getDeployedContractsCount() external view returns (uint256) {
        return deployedContracts.length;
    }
    
    /**
     * @dev Get a deployed contract by index
     */
    function getDeployedContract(uint256 _index) external view returns (address) {
        require(_index < deployedContracts.length, "Index out of bounds");
        return deployedContracts[_index];
    }
    
    /**
     * @dev Get all contracts deployed by a specific creator
     * Note: This is a gas-intensive operation and should only be used off-chain
     */
    function getContractsByCreator(address _creator) external view returns (address[] memory) {
        uint256 count = 0;
        
        // First, count how many contracts were deployed by this creator
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            address contractAddr = deployedContracts[i];
            LaunchMembershipV5 membership = LaunchMembershipV5(contractAddr);
            if (membership.clubCreator() == _creator) {
                count++;
            }
        }
        
        // Create an array to store the results
        address[] memory creatorContracts = new address[](count);
        uint256 index = 0;
        
        // Fill the array with contracts deployed by this creator
        for (uint256 i = 0; i < deployedContracts.length; i++) {
            address contractAddr = deployedContracts[i];
            LaunchMembershipV5 membership = LaunchMembershipV5(contractAddr);
            if (membership.clubCreator() == _creator) {
                creatorContracts[index] = contractAddr;
                index++;
            }
        }
        
        return creatorContracts;
    }
}