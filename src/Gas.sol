// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


contract GasContract {
    address[5] public administrators;
    uint256 totalSupply = 0; // cannot be updated
    uint256 paymentCounter = 0;
    uint256 tradePercent = 12;
    uint256 tradeMode = 0;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whitelistAmounts;
    mapping(address => bool) public whitelistStatuses;
    address contractOwner;
    bool constant mode = true;
    bool isReady = false;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    PaymentType constant defaultPayment = PaymentType.Unknown;

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        uint256 amount;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        bool adminUpdated;
    }

    bool wasLastOdd = true;
    mapping(address => bool) isOddWhitelistUser;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        address senderOfTx = msg.sender;
        require(
            senderOfTx == sender,
            "2"
        );
        uint256 usersTier = whitelist[senderOfTx];
        require(
            usersTier > 0,
            "3"
        );
        require(
            usersTier < 4,
            "4"
        );
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) payable {
        contractOwner = msg.sender;
administrators[0] = _admins[0];
        administrators[1] = _admins[1];
        administrators[2] = _admins[2];
        administrators[3] = _admins[3];
        administrators[4] = _admins[4];
        balances[contractOwner] = _totalSupply;
    }


    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
                break;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }



    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        require(
            _user != address(0),
            "6"
        );
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "7"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(
            _ID > 0,
            "9"
        );
        require(
            _amount > 0,
            ""
        );
        require(
            _user != address(0),
            "11"
        );

        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
                break;
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(
            _tier < 255,
            "12"
        );
        uint256 _tieri = _tier;
        if (_tier > 3) {
            _tieri = 3;
        } 
        whitelist[_userAddrs] = _tieri;
        wasLastOdd = !wasLastOdd;
         isOddWhitelistUser[_userAddrs] = wasLastOdd;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;
        whitelistAmounts[senderOfTx]=_amount;
        whitelistStatuses[senderOfTx]=true;

        require(
            balances[senderOfTx] >= _amount,
            "14"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whitelistStatuses[sender],
            whitelistAmounts[sender]
        );
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
