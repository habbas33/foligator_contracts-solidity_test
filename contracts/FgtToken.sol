//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20  {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function setOwner(address newOwner) external returns(bool);
    function mint( address _account, uint256 _amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 amount);

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}

contract FgtToken is IERC20 {
    string public override name = "Foligator Token";
    string public override symbol = "FGT";
    uint8 public override decimals = 18;
    uint256 public override totalSupply;
    bool private _paused;
    address public _owner; //owner is admin
    // address public _tokenSaleContract; 

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Paused(address account);
    event Unpaused(address account);
    event OwnershipSet(address indexed newOwner);
    // event TokenSaleContractSet(address indexed TokenSaleContract);
    
    constructor(){
        totalSupply = 0; 
        _owner = msg.sender;
        _balances[msg.sender] = totalSupply;
        _paused = false;
    }
    
    function getTimestamp() public view returns (uint) {
        return block.timestamp ;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner,"not token owner");
        _;
    }

    // modifier onlyTokenSaleContract() {
    //     require(msg.sender == _tokenSaleContract,"not token sale contract");
    //     _;
    // }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function setOwner(address newOwner) public onlyOwner virtual override returns (bool){
        require(newOwner != address(0));
        emit OwnershipSet(newOwner);
        _owner = newOwner;
        return true;
    }
    
    // function setTokenSaleContract(address newAddress) public onlyOwner returns (bool){
    //     require(newAddress != address(0));
    //     emit TokenSaleContractSet(newAddress);
    //     _tokenSaleContract = newAddress;
    //     return true;
    // }

    function balanceOf(address owner) public view override returns (uint256){
        return _balances[owner];
    }

    function transfer(address to, uint256 amount) public whenNotPaused virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) view public override returns(uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused virtual override returns (bool){
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function mint( address _account, uint256 _amount) public onlyOwner whenNotPaused virtual override returns (bool) {
        _mint(_account, _amount);
        emit Mint(_account, _amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        // _afterTokenTransfer(from, to, amount);
    }

    function _approve( address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount > 0);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        // _afterTokenTransfer(address(0), account, amount);
    }

    // function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual {
    //     // super._beforeTokenTransfer(from, to, amount);

    //     require(!paused(), "ERC20Pausable: token transfer while paused");
    // }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


