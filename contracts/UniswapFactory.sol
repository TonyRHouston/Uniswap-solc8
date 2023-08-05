// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

import "./interfaces/IUniswapPair.sol";
import "./interfaces/IUniswapFactory.sol";
import "./UniswapPair.sol";

contract UniswapFactory is IUniswapFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(UniswapPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    event Deployed(bytes32 init);

    constructor() {
        feeToSetter = tx.origin;
        feeTo = tx.origin;
        emit Deployed(INIT_CODE_PAIR_HASH);
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        override
        returns (address pair)
    {
        require(tokenA != tokenB, "Uniswap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Uniswap: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Uniswap: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(UniswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "Uniswap: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "Uniswap: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
