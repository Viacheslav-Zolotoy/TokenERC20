// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;

    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint) {
        return 18; //1 token = 1 wei
    }

    function totalSupply() external view returns (uint) {
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }
    constructor(
        string memory name_,
        string memory symbol_,
        uint initialSupply,
        address shop
    ) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, shop);
    }
    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }
    function transfer(
        address to,
        uint amount
    ) external enoughTokens(msg.sender, amount) {
        _beforTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    // введення tokena у обіг
    function mint(uint amount, address shop) public onlyOwner {
        _beforTokenTransfer(address(0), shop, amount);

        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function burn(address _from, uint amount) public onlyOwner {
        _beforTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    function allowance(
        address _owner,
        address spender
    ) public view returns (uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);
    }

    function _approve(
        address sender,
        address spender,
        uint amount
    ) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public enoughTokens(sender, amount) {
        _beforTokenTransfer(sender, recipient, amount);
        // require( allowances[sender][recipient] >= amount, "check allowance!")
        allowances[sender][recipient] -= amount; //error!
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _beforTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
}

contract MCSToken is ERC20 {
    constructor(address shop) ERC20("MCSToken", "MCT", 20, shop) {}
}

contract MShop {
    IERC20 public token;
    address payable public owner;
    event Bought(uint _amount, address indexed _buyer);
    event Sold(uint _amount, address indexed _seller);

    constructor() {
        token = new MCSToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }
    function sell(uint _amountToSell) external {
        address payable seller = payable(msg.sender);
        require(
            _amountToSell > 0 && token.balanceOf(seller) >= _amountToSell,
            "incorrect amount!"
        );
        uint allowance = token.allowance(seller, address(this));
        require(allowance >= _amountToSell, "check allowance!");
        token.transferFrom(seller, address(this), _amountToSell);
        payable(seller).transfer(_amountToSell); //2300 gas
        emit Sold(_amountToSell, seller);
    }

    receive() external payable {
        uint tokensToBuy = msg.value; //1wei = 1token
        require(tokensToBuy > 0, "not enough funds!");

        require(tokenBalance() >= tokensToBuy, "not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function withdrawFunds(uint _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        owner.transfer(_amount);
    }
}
