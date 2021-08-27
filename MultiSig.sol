// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract MultiSig {
    address[] public owners;
    uint public required;
    Transaction[] public transactions;
    uint public txIndex;
    

    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(uint => uint) public numConfirmations;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0 && _required > 0 && _required < _owners.length);
        owners = _owners;
        required = _required;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    } 

    function getTransactionIds(bool _pending, bool _executed) external view returns (uint[] memory) {
        uint[] memory ids = new uint[](getTransactionCount(_pending, _executed));

        for(uint i = 0; i < ids.length; i++) {
            ids[i] = i;
        }

        return ids;
    }

    function getTransactionCount(bool _pending, bool _executed) public view returns (uint) {
        uint numberConfirmations;
        for(uint i = 0; i < transactions.length; i++) {
            if(transactions[i].executed) {
                numberConfirmations += 1;
            }
        }
        if(_pending && _executed) {
            return transactionCount();
        } else if(_pending) {
            return transactionCount() - numberConfirmations;
        } else if(_executed) {
            return numberConfirmations;
        }
    }

    function transactionCount() public view returns (uint) {
        return transactions.length;
    }

    function addTransaction(address payable _destination, uint _value) internal returns (uint) {
        uint txNum = txIndex;
        Transaction memory newTx = Transaction(_destination, _value, false);
        transactions.push(newTx);
        txIndex+=1;
        return txNum;
    }

    function confirmTransaction(uint _txId) public {
        bool ret = false;
        for(uint i = 0; i < owners.length-1; i++) {
            if(owners[i] == msg.sender) {
                ret = true;
            }
        }
        require(ret);
        confirmations[_txId][msg.sender] = true;
        numConfirmations[_txId]+=1;
        if(isConfirmed(_txId) == true) {
            executeTransaction(_txId);
        }
        
    }

    function getConfirmationsCount(uint _txId) public view returns (uint) {
        return numConfirmations[_txId];
    }

    function getConfirmations(uint _txId) external view returns (address[] memory) {
        address[] memory confirmers = new address[](getConfirmationsCount(_txId));
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[_txId][owners[i]]) {
                confirmers[i] = owners[i];
            }
            
        }
        return confirmers;
    }

    function submitTransaction(address payable _destination, uint _value) external {
        uint txId = addTransaction(_destination, _value);
        confirmTransaction(txId);
    }

    function isConfirmed(uint _txId) public view returns (bool) {
        if(getConfirmationsCount(_txId) >= required) {
            return true;
        }

        return false;
    }

    function executeTransaction(uint _txId) internal {
        require(isConfirmed(_txId));
        transactions[_txId].destination.transfer(transactions[_txId].value);
        transactions[_txId].executed = true;
    }

    receive() external payable {}
}
