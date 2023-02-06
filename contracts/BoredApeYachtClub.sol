// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC721.sol";
import "./library/Ownable.sol";


/**
  * @title BoredApeYachtClub 合同
  * @dev 扩展 ERC721 不可替代令牌标准基本实现
  */
contract BoredApeYachtClub is ERC721, Ownable {
    using SafeMath for uint256;

    string public BAYC_PROVENANCE = "";
    //  开始mint区块
    uint256 public startingIndexBlock;
    //  开始索引
    uint256 public startingIndex;

    uint256 public constant apePrice = 80000000000000000; //0.08 ETH
    //  每人最大购买额度
    uint public constant maxApePurchase = 20;
    //  无聊猿最大数量
    uint256 public MAX_APES;
    // 开始售卖
    bool public saleIsActive = false;
    //  可以铸造的时间
    uint256 public REVEAL_TIMESTAMP;

    constructor(string memory name, string memory symbol, uint256 maxNftSupply, uint256 saleStart) ERC721(name, symbol) {
        MAX_APES = maxNftSupply;    //  最大购买数量
        REVEAL_TIMESTAMP = saleStart + (86400 * 9); // 可以mint的时间
    }

    // 取钱
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * 项目方批量调用 储备
     */
    function reserveApes() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * 设置可以铸造的时间
     */
    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    } 

    /*     
    设置起源地的hash值
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BAYC_PROVENANCE = provenanceHash;
    }
    
    /**
     * 设置baseURI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * 开始暂停销售状态
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
    * Mints Bored Apes
    */
    function mintApe(uint numberOfTokens) public payable {
        // 开始售卖
        require(saleIsActive, "Sale must be active to mint Ape");
        // 最多一次20个
        require(numberOfTokens <= maxApePurchase, "Can only mint 20 tokens at a time");
        // mint数量不能超过最大数量
        require(totalSupply().add(numberOfTokens) <= MAX_APES, "Purchase would exceed max supply of Apes");
        // 发送的数量 => 0.08 * num  可以多发不能少发
        require(apePrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            // 总量100，轮到我mint总量99。但是我发送了 10 * 0.8个eth 剩余的不还。。
            if (totalSupply() < MAX_APES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        // 设置起始mint区块
        if (startingIndexBlock == 0 && (totalSupply() == MAX_APES || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        } 
    }

    /**
     * 设置开始的索引
     */
    function setStartingIndex() public {
        // 索引为0
        require(startingIndex == 0, "Starting index is already set");
        // 确定已经被mint过               
        require(startingIndexBlock != 0, "Starting index block must be set");
        // 计算起始编号值
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_APES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        // 最坏的情况下如果这个函数调用的太晚了  就用下面的方式计算起始编号的值
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_APES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * 设置开始区块时间
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}