pragma solidity 0.5.10;

import "./SafeMath.sol";

interface IBMapping {
    function checkAddress(string calldata name) external view returns (address contractAddress);
    function checkOwners(address man) external view returns (bool);
}

interface IBNEST {
    function totalSupply() external view returns (uint supply);
    function balanceOf( address who ) external view returns (uint value);
    function allowance( address owner, address spender ) external view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) external returns (bool ok);
    function approve( address spender, uint value ) external returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
    
    function balancesStart() external view returns(uint256);
    function balancesGetBool(uint256 num) external view returns(bool);
    function balancesGetNext(uint256 num) external view returns(uint256);
    function balancesGetValue(uint256 num) external view returns(address, uint256);
}

// NestNode contract
interface SuperMan {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Guardian node nest storage
 */
contract NEST_NodeSave {
    IBMapping mappingContract;                      
    IBNEST nestContract;                             
    
    /**
    * @dev Initialization method
    * @param map Mapping contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(address(map));              
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));            
    }
    
    /**
    * @dev Change mapping contract
    * @param map Mapping contract address
    */
    function changeMapping(address map) public onlyOwner {
        mappingContract = IBMapping(address(map));              
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));            
    }
    
    /**
    * @dev Transfer out nest
    * @param amount Transfer out quantity
    * @param to Transfer out target
    * @return Actual transfer out quantity
    */
    function turnOut(uint256 amount, address to) public onlyMiningCalculation returns(uint256) {
        uint256 leftNum = nestContract.balanceOf(address(this));
        if (leftNum >= amount) {
            nestContract.transfer(to, amount);
            return amount;
        } else {
            return 0;
        }
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }

    modifier onlyMiningCalculation(){
        require(address(mappingContract.checkAddress("nodeAssignment")) == msg.sender);
        _;
    }
    
}

/**
 * @title Guardian node receives data
 */
contract NEST_NodeAssignmentData {
    using SafeMath for uint256;
    IBMapping mappingContract;              
    uint256 nodeAllAmount = 9546345842385995696603;                                 
    mapping(address => uint256) nodeLatestAmount;               
    
    /**
    * @dev Initialization method
    * @param map Mapping contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(map); 
    }
    
    /**
    * @dev Change mapping contract
    * @param map Mapping contract address
    */
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
    }
    
    //  Add nest
    function addNest(uint256 amount) public onlyNodeAssignment {
        nodeAllAmount = nodeAllAmount.add(amount);
    }
    
    //  View cumulative total
    function checkNodeAllAmount() public view returns (uint256) {
        return nodeAllAmount;
    }
    
    //  Record last received quantity
    function addNodeLatestAmount(address add ,uint256 amount) public onlyNodeAssignment {
        nodeLatestAmount[add] = amount;
    }
    
    //  View last received quantity
    function checkNodeLatestAmount(address add) public view returns (uint256) {
        return nodeLatestAmount[address(add)];
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
    
    modifier onlyNodeAssignment(){
        require(address(msg.sender) == address(mappingContract.checkAddress("nodeAssignment")));
        _;
    }
}

/**
 * @title Node assignment contract
 */
contract NEST_NodeAssignment {
    
    using SafeMath for uint256;
    IBMapping mappingContract;                              //  Mapping contract
    IBNEST nestContract;                                    //  NEST contract
    SuperMan supermanContract;                              //  NestNode contract
    NEST_NodeSave nodeSave;                                 //  NestNode save contract
    NEST_NodeAssignmentData nodeAssignmentData;             //  NestNode data assignment contract

    /**
    * @dev Initialization method
    * @param map Voting contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.checkAddress("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
    /**
    * @dev Reset voting contract
    * @param map Voting contract address
    */
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
        nestContract = IBNEST(address(mappingContract.checkAddress("nest")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.checkAddress("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
    /**
    * @dev Deposit NEST token
    * @param amount Amount of deposited NEST
    */
    function bookKeeping(uint256 amount) public {
        require(amount > 0);
        require(nestContract.transferFrom(address(msg.sender), address(nodeSave), amount));
        nodeAssignmentData.addNest(amount);
    }
    
    // NestNode receive and settlement
    function nodeGet() public {
        require(address(msg.sender) == address(tx.origin));
        require(supermanContract.balanceOf(address(msg.sender)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
        uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
        require(nestContract.balanceOf(address(nodeSave)) >= getAmount);
        nodeSave.turnOut(getAmount,address(msg.sender));
        nodeAssignmentData.addNodeLatestAmount(address(msg.sender),allAmount);
    }
    
    // NestNode transfer settlement
    function nodeCount(address fromAdd, address toAdd) public {
        require(address(supermanContract) == address(msg.sender));
        require(supermanContract.balanceOf(address(fromAdd)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        uint256 amountFrom = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(fromAdd)));
        uint256 getAmountFrom = amountFrom.mul(supermanContract.balanceOf(address(fromAdd))).div(1500);
        if (nestContract.balanceOf(address(nodeSave)) >= getAmountFrom) {
            nodeSave.turnOut(getAmountFrom,address(fromAdd));
            nodeAssignmentData.addNodeLatestAmount(address(fromAdd),allAmount);
        }
        uint256 amountTo = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(toAdd)));
        uint256 getAmountTo = amountTo.mul(supermanContract.balanceOf(address(toAdd))).div(1500);
        if (nestContract.balanceOf(address(nodeSave)) >= getAmountTo) {
            nodeSave.turnOut(getAmountTo,address(toAdd));
            nodeAssignmentData.addNodeLatestAmount(address(toAdd),allAmount);
        }
    }
    
    // NestNode receivable amount
    function checkNodeNum() public view returns (uint256) {
         uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
         uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
         uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
         return getAmount; 
    }
    
    // Administrator only
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender));
        _;
    }
}

