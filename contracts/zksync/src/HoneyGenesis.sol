// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract Idols100x is ERC721A, IERC2981, Ownable {
    event NFTMinted(address indexed minter, uint256 amount, uint256 value);
    event FundWithdrawn(address owner, uint256 amount);
    event BatchMetadataUpdate(uint256 indexed fromTokenId, uint256 indexed toTokenId);

    uint256 public constant TOTAL_SUPPLY_CAP = 5000; // max 5000 NFTs normal minting
    uint256 private constant VIP_SUPPLY_CAP = 1000; // max 1000 NFTs for VIP minting

    uint256 private constant MINT_VIP_PRICE = 0.069 ether; // 0.069 ETH minting fee for VIP
    uint256 public constant MINT_UNIT_PRICE = 0.07 ether; // 0.07 ETH minting fee for normal wallets
    uint256 public constant PRICE_INCREMENT = 0.007 ether; // 0.007 ETH price increment

    uint256 private constant SUPPLY_INCREMENT_STEPSIZE = 500; // After the first 1000 NFTs, the price will increase every 500 NFTs
    uint256 public constant MAX_MINT_AMOUNT = 20; // Max 20 NFTs for each normal wallets

    uint256 public tokenCountNormal; // normal minted NFTs
    uint256 public tokenCountVIP; // vip minted NFTs

    string public baseURI;

    mapping(address => uint256) private _VIPMintQuota; // whitelisted wallets can only mint up to a quota at VIP price
    mapping(address => uint256) private pendingBalances; // Payout mapping

    // Payout addresses
    address private constant KPA = 0x428Deb81A93BeD820068724eb1fCc7503d71e417;
    address private constant HGPA = 0x62C414e104D0a32c3723b59da5854f8b06116831;
    uint256 private constant THREEDOLLARS_ETH = 900000000000000; // $3 ETH collected by Kingdomly (last checked Mar 19 2024 1:10 PM UTC+08)

    error Overflow();
    error InsufficientEther(uint256 required, uint256 provided);
    error ExceedsMaxSupply(uint256 requested, uint256 available);
    error ExceedsVIPMaxSupply(uint256 requested, uint256 available);

    constructor(string memory _initialBaseURI) ERC721A("Idols100x", "I100X") Ownable(msg.sender) {
        tokenCountNormal = 0;
        tokenCountVIP = 0;
        baseURI = _initialBaseURI;
    }

    function mint(uint256 amount) public payable {
        address minter = msg.sender;
        uint256 totalCost = amount * _calcPrice(tokenCountNormal);

        // Kingdomly Fees
        uint256 kingdomlyThreeDollars = (THREEDOLLARS_ETH * amount); //$3 kingdomly fee

        uint256 totalCostWithFees = totalCost + kingdomlyThreeDollars;

        if (msg.value < totalCostWithFees) {
            revert InsufficientEther({required: totalCostWithFees, provided: msg.value});
        }

        if (tokenCountNormal + amount > TOTAL_SUPPLY_CAP) {
            revert ExceedsMaxSupply({requested: amount, available: TOTAL_SUPPLY_CAP - tokenCountNormal});
        }

        require(
            amount + _numberMinted(msg.sender) - _VIPMintQuota[msg.sender] <= MAX_MINT_AMOUNT, "Exceeds max mint amount"
        );

        //Implemented payout system
        pendingBalances[HGPA] += totalCost; // To HoneyPot
        pendingBalances[KPA] += kingdomlyThreeDollars; // To Kingdomly

        _safeMint(msg.sender, amount);
        tokenCountNormal += amount;

        emit NFTMinted(minter, amount, msg.value);
        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCostWithFees;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function mintbyKingdomly(uint256 amount) public payable {
        uint256 currentPrice = _calcPrice(tokenCountNormal);
        uint256 totalCost = currentPrice * amount;

        uint256 kingdomlyFee = ((totalCost * 3) / 100) + (THREEDOLLARS_ETH * amount); //$3 in wei + 3% fee
        uint256 totalCostWithFees = totalCost + kingdomlyFee;

        if (msg.value < totalCostWithFees) {
            revert InsufficientEther({required: totalCostWithFees, provided: msg.value});
        }

        if (tokenCountNormal + amount > TOTAL_SUPPLY_CAP) {
            revert ExceedsMaxSupply({requested: amount, available: TOTAL_SUPPLY_CAP - tokenCountNormal});
        }

        require(
            amount + _numberMinted(msg.sender) - _VIPMintQuota[msg.sender] <= MAX_MINT_AMOUNT, "Exceeds max mint amount"
        );

        // Update balances
        pendingBalances[HGPA] += totalCost; // To owner
        pendingBalances[KPA] += kingdomlyFee; // Fee portion

        _safeMint(msg.sender, amount); // gas efficient, you can use batchMint function from ERC721A
        tokenCountNormal += amount;

        emit NFTMinted(msg.sender, amount, msg.value);

        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCostWithFees;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    function mintVIP(uint256 amount) public payable {
        address minter = msg.sender;
        uint256 totalCost = amount * MINT_VIP_PRICE;

        // Kingdomly Fees
        uint256 kingdomlyThreeDollars = (THREEDOLLARS_ETH * amount); //$3 kingdomly fee
        uint256 totalCostWithFees = totalCost + kingdomlyThreeDollars;

        if (msg.value < totalCostWithFees) {
            revert InsufficientEther({required: totalCostWithFees, provided: msg.value});
        }

        if (tokenCountVIP + amount > VIP_SUPPLY_CAP) {
            revert ExceedsVIPMaxSupply({requested: amount, available: VIP_SUPPLY_CAP - tokenCountVIP});
        }

        require(_VIPMintQuota[minter] >= amount, "Exceeds VIP mint quota");

        _VIPMintQuota[minter] -= amount;

        // Update balances
        pendingBalances[HGPA] += totalCost; // To HoneyPot
        pendingBalances[KPA] += kingdomlyThreeDollars; // Fee portion

        _safeMint(msg.sender, amount);
        tokenCountVIP += amount;

        emit NFTMinted(minter, amount, msg.value);
        //Added a refund mechanism in case the user sends too much eth
        uint256 excess = msg.value - totalCostWithFees;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    // UPDATED WITHDRAW FUNCTION
    function withdraw() public onlyOwner {
        // Checker
        require(pendingBalances[HGPA] > 0, "No funds to withdraw");

        uint256 honeyPotPayout = pendingBalances[HGPA];
        uint256 kingdomlyPayout = pendingBalances[KPA];

        // Set state to 0
        pendingBalances[HGPA] = 0;
        pendingBalances[KPA] = 0; // We also included our address

        // Transaction
        (bool success1,) = payable(HGPA).call{value: honeyPotPayout}("");
        (bool success2,) = payable(KPA).call{value: kingdomlyPayout}(""); // We also included our address

        require(success1 && success2, "Transfer failed");
    }

    // KINGDOMLY WITHDRAW FUNCTION
    function withdrawFeeFunds() public {
        // Check
        require(msg.sender != KPA, "Unauthorized, not the Kingdomly Address");
        require(pendingBalances[KPA] > 0, "No funds to withdraw");

        // Set state to 0
        uint256 fee = pendingBalances[KPA];
        pendingBalances[KPA] = 0;

        (bool success,) = payable(KPA).call{value: fee}("");
        require(success, "Transfer failed");
    }

    function getCurrentPrice() public view returns (uint256) {
        return _calcPrice(tokenCountNormal);
    }

    function getNextNFTPrice() public view returns (uint256) {
        uint256 nexttokenId = tokenCountNormal + SUPPLY_INCREMENT_STEPSIZE;
        if (nexttokenId > TOTAL_SUPPLY_CAP) {
            revert Overflow();
        }
        return _calcPrice(nexttokenId);
    }

    function _calcPrice(uint256 priceParam) private pure returns (uint256) {
        uint256 priceIncrements = priceParam / SUPPLY_INCREMENT_STEPSIZE + 1;
        return MINT_UNIT_PRICE + (priceIncrements * PRICE_INCREMENT);
    }

    function getVIPPrice() public pure returns (uint256) {
        return MINT_VIP_PRICE;
    }

    function getTotalVIPNFTCount() public pure returns (uint256) {
        return VIP_SUPPLY_CAP;
    }

    // Function to read the balance of an address
    function getVIPMintQuota(address user) public view returns (uint256) {
        return _VIPMintQuota[user];
    }

    // Function to increment the balance of an address
    function incrementVIPMintQuota(address[] calldata user, uint256[] calldata amount) public onlyOwner {
        require(user.length == amount.length, "User and amount arrays must be of the same length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
        }

        for (uint256 i = 0; i < user.length; i++) {
            _VIPMintQuota[user[i]] += amount[i];
        }
    }

    // Override for royalty info to always return the owner as the receiver
    function royaltyInfo(uint256, /*tokenId*/ uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = payable(HGPA); // Royalties always go to the owner
        royaltyAmount = (salePrice * 5) / 100; // Assuming a flat 5% royalty
        return (receiver, royaltyAmount);
    }

    // Sets the base URI for the token metadata. Only the contract owner can call this function.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
        emit BatchMetadataUpdate(1, type(uint256).max); // Signal that all token metadata has been updated
    }

    // Overrides the start token ID function from the ERC721A contract.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // Returns the base URI for the token metadata.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
