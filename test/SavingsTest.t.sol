// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Savings.sol";

// Mock ERC20 token for testing
contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalSupply;
    string public name = "Test Token";
    string public symbol = "TEST";
    uint8 public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

contract SavingsTest is Test {
    TimeLockSavings public savings;
    MockERC20 public token;
    
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    uint256 public constant INITIAL_BALANCE = 1000000 * 10**18; // 1M tokens
    
    function setUp() public {
        token = new MockERC20();
        savings = new TimeLockSavings(address(token));
        
        // Mint tokens to test users
        token.mint(alice, 1000 * 10**18);
        token.mint(bob, 500 * 10**18);
        token.mint(charlie, INITIAL_BALANCE);
        
        // Approve the savings contract to spend tokens
        vm.prank(alice);
        token.approve(address(savings), INITIAL_BALANCE);
        
        vm.prank(bob);
        token.approve(address(savings), INITIAL_BALANCE);
        
        vm.prank(charlie);
        token.approve(address(savings), INITIAL_BALANCE);
    }
    
    
    // Test 1: Demonstrate parameter order bug in actual withdrawal function
    function testWithdrawalParameterOrderBug() public {
        uint256 depositAmount = 1000 * 10**18; // 1000 tokens
        
        // Alice deposits
        vm.prank(alice);
        savings.deposit(depositAmount);
        
        // Fast forward past minimum lock period (90 days)
        vm.warp(block.timestamp + 90 days);
        
        // Calculate what the reward should be with correct parameters
        uint256 correctReward = savings.calculateReward(depositAmount, 90 days);
        uint256 expectedCorrectTotal = depositAmount + correctReward;
        
        // Calculate what the reward actually is with buggy parameters (as used in withdraw)
        uint256 buggyReward = savings.calculateReward(90 days, depositAmount);
        uint256 expectedBuggyTotal = depositAmount + buggyReward;
        
        console.log("Expected with CORRECT parameters:", expectedCorrectTotal);
        console.log("Expected with BUGGY parameters:", expectedBuggyTotal);
        console.log("Calculation difference:", expectedCorrectTotal - expectedBuggyTotal);
        
        // The buggy calculation should be different from correct calculation
        assertTrue(expectedBuggyTotal != expectedCorrectTotal, "Parameter order bug not detected");
        
        // Try to withdraw - this should fail due to insufficient balance
        // because the buggy calculation tries to pay more than the contract has
        vm.prank(alice);
        vm.expectRevert("Insufficient balance");
        savings.withdraw(0);
        
        console.log("CRITICAL BUG: Withdrawal fails due to parameter order error!");
        console.log("The contract tries to pay:", expectedBuggyTotal);
        console.log("But only has:", depositAmount);
        console.log("This proves the parameter order bug breaks the withdrawal function!");
    }

   
}
