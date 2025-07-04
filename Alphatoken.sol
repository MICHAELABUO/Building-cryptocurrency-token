// SPDX-License-Identifier: MIT
//contracts/alphatoken.sol
//Building cryptocurrency token
pragma solidity ^0.8.17;

contract AlphaToken {
    string private _name = "AlphaToken";
    string private _symbol = "ALPHA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    uint256 private _cap;
    uint256 private _sellTax = 1; // 0.01% sell tax
    uint256 private _tokenPrice = 0.001 ether; // 0.001 Ether per token
    address private _owner;
    bool private _paused;
    address private _taxCollector;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Destroyed(address indexed account, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Token transfer paused");
        _;
    }

    constructor(uint256 initialSupply, uint256 cap, address taxCollector) {
        require(initialSupply <= cap, "Initial supply exceeds cap");
        _cap = cap;
        _owner = payable(msg.sender);
        _taxCollector = taxCollector;
        _paused = false;
        _mint(msg.sender, initialSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function Cap() public view returns (uint256) {
        return _cap;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public whenNotPaused {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "Burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    function pause() public onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function destroy(uint256 amount) public onlyOwner {
        require(amount <= _balances[_owner], "Destroy amount exceeds balance");
        _burn(_owner, amount);
        emit Destroyed(_owner, amount);
    }

    function buyTokens() public payable whenNotPaused {
        require(msg.value >= _tokenPrice, "Ether sent is less than the token price");
        uint256 tokensToBuy = (msg.value * (10 ** uint256(_decimals))) / _tokenPrice;
        _transfer(_owner, msg.sender, tokensToBuy);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        uint256 tax = 0;
        if (recipient == _taxCollector) {
            tax = (amount * _sellTax) / 10000; // Calculate the 0.01% tax
        }

        uint256 amountAfterTax = amount - tax;
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amountAfterTax;
        if (tax > 0) {
            _balances[_taxCollector] += tax;
            emit Transfer(sender, _taxCollector, tax);
        }

        emit Transfer(sender, recipient, amountAfterTax);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");
        require(_totalSupply + amount <= _cap, "Cap exceeded");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
    function destroy () public onlyOwner {
        selfdestruct(payable(_owner));
        }
    // Fallback function to receive Ether when `buyTokens` is called
    receive() external payable {
        buyTokens();
    }
}
//    888 888 888  000000000000000000









