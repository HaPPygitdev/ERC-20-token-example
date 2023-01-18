// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;

    function name() external view returns(string memory){
        return _name;
    }

    function symbol() external view returns(string memory){
        return _symbol;
    }

        function decimals() external pure returns(uint){
        return 18; // 1 wei = 1 token
    }

    function totalSupply() external view returns(uint){
        return totalTokens;
    }

    function balanceOf(address account) public  view returns(uint) {
        return balances[account];
    }

    // transfer gasLimit = 2300
    function transfer(address to, uint amount) external enoughTokens(msg.sender,amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] +=amount;
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external enoughTokens(sender,amount) {
        _beforeTokenTransfer(sender, recipient, amount);
        require (allowances[sender][recipient] >= amount, "check allowance");
        allowances[sender][msg.sender] -= amount;
        
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function allowance(address _owner, address spender) public view returns(uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public {
        allowances[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
    }

    function mint(uint amount, address router) public onlyOwner {
        _beforeTokenTransfer(address(0), router, amount);
        balances[router] +=amount;
        totalTokens += amount;
        emit Transfer(address(0), router, amount);
    }

     //additional functions

    function _approve(address sender, address spender, uint amount) internal virtual{
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function burn(address _from, uint amount) public onlyOwner {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to, 
        uint amount
    ) internal virtual {}

    //end of additional functions
    
    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not an owner");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint initialSupply, address router){
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, router);
    } 
}


contract SoulToken is ERC20{
    constructor(address router) ERC20("SoulToken", "SOUL", 333, router) {}
}

contract SoulShop {
    IERC20 public token;
    address payable public owner;
    event Purchase(uint _amount, address indexed _buyer);
    event Sale(uint _amount, address indexed _seller);    

    constructor() {
        token = new SoulToken(address(this));
        owner = payable(msg.sender);

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not an owner");
        _;
    }

    function tokenBalance() public view returns (uint){
        return token.balanceOf(address(this));
    }

    function sell(uint _amountToSell) external {
        require(
            _amountToSell > 0 &&
            token.balanceOf(msg.sender) >= _amountToSell,
            "incorrect amount!"
        );

        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "check allowance!");
    
        token.transferFrom(msg.sender, address(this), _amountToSell);

        payable(msg.sender).transfer(_amountToSell);

        emit Sale(_amountToSell, msg.sender);
    }

    receive() external payable{
        uint tokensToBuy = msg.value; // 1 wei = 1 token
        require(tokensToBuy > 0, "not enough funds!");

        require(tokenBalance() >= tokensToBuy, "not enough tokens!");

        token.transfer(msg.sender, tokensToBuy);
        emit Purchase(tokensToBuy, msg.sender); 
    }


}