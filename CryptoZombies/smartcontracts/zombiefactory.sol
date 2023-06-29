pragma solidity ^0.6.6;

import "./ownable.sol";
import "./safemath.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract ZombieFactory is Ownable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event NewZombie(uint zombieId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 days;

    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomResult;

    struct Zombie {
        string name;
        uint dna;
        uint32 level;
        uint32 readyTime;
        uint16 winCount;
        uint16 lossCount;
    }

    Zombie[] public zombies;

    mapping(uint => address) public zombieToOwner;
    mapping(address => uint) ownerZombieCount;

    constructor()
        public
        VRFConsumerBase(
            0x6168499c0cFfCaCD319c818142124B7A15E857ab, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 100000000000000000;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        randomResult = randomness;
    }

    function _createZombie(string memory _name, uint _dna) internal {
        uint id = zombies.push(
            Zombie(_name, _dna, 1, uint32(now + cooldownTime), 0, 0)
        ) - 1;
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender] = ownerZombieCount[msg.sender].add(1);
        emit NewZombie(id, _name, _dna);
    }

    function createRandomZombie(string _name) public {
        require(ownerZombieCount[msg.sender] == 0);
        uint randDna = randomResult;
        randDna = randDna - (randDna % 100);
        _createZombie(_name, randDna);
    }
}
