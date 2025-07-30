pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IENS {
    function owner(bytes32 node) external view returns (address);
}

contract AirdropManager is Ownable {
    IERC20 public token;
    IENS public ens;
    IERC721 public bayc;
    IERC721 public mayc;

    uint256 public constant REGISTRATION_START = 1756771200; // September 1, 2025, 00:00:00 UTC
    uint256 public constant REGISTRATION_END = 1759363200;   // September 30, 2025, 23:59:59 UTC
    uint256 public constant TOKENS_PER_CLAIM = 100 * 10**18; // 100 tokens per claim

    mapping(address => bool) public registered;
    mapping(address => bool) public claimed;

    event Registered(address indexed user);
    event Claimed(address indexed user, uint256 amount);

    constructor(
        address _token,
        address _ens,
        address _bayc,
        address _mayc
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        ens = IENS(_ens);
        bayc = IERC721(_bayc);
        mayc = IERC721(_mayc);
    }

    function isEligible(address user) public view returns (bool) {
        // Check ENS ownership (example: check if user owns any .eth name)
        bytes32 node = keccak256(abi.encodePacked(user, ".eth"));
        bool hasENS = ens.owner(node) == user;

        // Check BAYC or MAYC ownership
        bool hasBAYC = bayc.balanceOf(user) > 0;
        bool hasMAYC = mayc.balanceOf(user) > 0;

        return hasENS || hasBAYC || hasMAYC;
    }

    function register() external {
        require(block.timestamp >= REGISTRATION_START, "Registration not yet started");
        require(block.timestamp <= REGISTRATION_END, "Registration period ended");
        require(!registered[msg.sender], "Already registered");
        require(isEligible(msg.sender), "Not eligible for airdrop");

        registered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    function claim() external {
        require(registered[msg.sender], "Not registered");
        require(!claimed[msg.sender], "Already claimed");
        require(token.balanceOf(address(this)) >= TOKENS_PER_CLAIM, "Insufficient tokens in contract");

        claimed[msg.sender] = true;
        token.transfer(msg.sender, TOKENS_PER_CLAIM);
        emit Claimed(msg.sender, TOKENS_PER_CLAIM);
    }

    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");
        token.transfer(to, amount);
    }
}
