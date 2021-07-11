// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IPancakeswapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract HOPReward is Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private lastUserClaimed;
    IERC20 hop;
    IPancakeswapRouter router;
    uint256 public minimumSwapAmount = 1 * 10**9 * 10**9;
    address payable public donationAddress;
    address[] public nonCirculatingAddresses;

    constructor(address hopAddress, address routerAddress, address _donationAddress) {
        hop = IERC20(hopAddress);
        router = IPancakeswapRouter(routerAddress);
        donationAddress = payable(_donationAddress);
    }

    receive() external payable {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDonationAddress(address _donationAddress) external onlyOwner() {
        donationAddress = payable(_donationAddress);
    }

    function setMinimumSwapAmount(uint256 _minimumSwapAmount) external onlyOwner{
        minimumSwapAmount = _minimumSwapAmount;
    }

    function withdraw(address _token) external onlyOwner{
        IERC20 token = IERC20(_token);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function claim() external {
        address payable sender = payable(msg.sender);
        uint256 hopBalance = hop.balanceOf(address(this));
        uint256 senderHopBalance = hop.balanceOf(sender);
        bool success;

        require(senderHopBalance > 0, "Sender is not hop holder");
        require(getAccountNextRewardTimestamp(sender) <= block.timestamp, "Sender next claim time has not reached");

        if ( hopBalance >= minimumSwapAmount) {
            address[] memory path = new address[](2);
            path[0] = address(hop);
            path[1] = router.WETH();
            hop.approve(address(router), hopBalance);
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                hopBalance,
                0, // accept any amount
                path,
                address(this),
                block.timestamp
            );
            uint256 bnbBalance = address(this).balance;
            uint256 donationAmount = bnbBalance.div(3);
            (success,) = donationAddress.call{value:donationAmount}("");
            require(success, "Transfer donation failed.");
        }
        lastUserClaimed[sender] = block.timestamp;
        uint256 senderReward = getAccountReward(sender);
        (success,) = sender.call{value:senderReward}("");
        require(success, "Transfer reward failed.");
    }

    function setNonCirculatingAccount(address[] calldata _nonCirculatingAddress) external onlyOwner(){
        nonCirculatingAddresses = _nonCirculatingAddress;
    }

    function getHopCirculatingSupply() public view returns (uint256) {
        uint256 supply = hop.totalSupply();
        for (uint i=0; i<nonCirculatingAddresses.length; i++) {
            uint256 bal = hop.balanceOf(nonCirculatingAddresses[i]);
            supply -= bal;
        }
        return supply;
    }

    function getAccountReward(address accountAddress) public view returns (uint256) {
        uint256 bnbBalance = address(this).balance;
        uint256 maxReward = bnbBalance.mul(5).div(1000);
        uint256 reward = hop.balanceOf(accountAddress)
            .mul(bnbBalance)
            .div(getHopCirculatingSupply());
        if (reward > maxReward) {
            return maxReward;
        }
        return reward;
    }

    function getAccountNextRewardTimestamp(address accountAddress) public view returns(uint256) {
        if (lastUserClaimed[accountAddress] == 0) {
            return 0;
        }
        return lastUserClaimed[accountAddress] + 1 days;
    }
}
