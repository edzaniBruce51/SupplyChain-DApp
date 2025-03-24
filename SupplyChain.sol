// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SupplyChain {

    uint32 public product_id = 0;
    uint32 public participant_id = 0;
    uint32 public owner_id = 0;

    struct Product {       // struct stands for(structure of product/ collection of variables that make up a product)
        string modelNumber;
        string partNumber;
        string serialNumber;
        address productOwner;
        uint32 cost;
        uint32 mfgTimestamp;
    }

    mapping(uint32 => Product) public products;    // creates an indexed list of product structures that are going to be indexed by product_id and we call the list products
    
    struct participant {
        string userName;
        string password;
        string participantType;
        address participantAddress;
    }

    mapping(uint32 => participant) public participants;    // creates an indexed list of participant structures that are going to be indexed by participant_id and we call the list participants

    struct ownership {
        uint32 product_id;  // Changed from productId to product_id
        uint32 owner_id;
        uint32 trxTimeStamp;
        address productOwner;
    }

    mapping(uint32 => ownership) public ownerships;    // ownerships by ownership ID (owner_id)
    mapping(uint32 => uint32[]) public ownershipsByProduct;

    event TransferOwnership(uint32 productId);

    function addParticipant(string memory _name, string memory _pass, address _pAdd, string memory _pType) public returns(uint32){
        uint32 userId = participant_id++;
        participants[userId].userName = _name;
        participants[userId].password = _pass;
        participants[userId].participantAddress = _pAdd;
        participants[userId].participantType = _pType;
        return userId;

    }

    function getParticipant(uint32 _product_id) public view returns(string memory, address, string memory){
        return (participants[_product_id].userName, participants[_product_id].participantAddress, participants[_product_id].participantType);
    }

    function addProduct(uint32 _ownerId, string memory _modelNumber, string memory _partNumber, string memory _serialNumber, uint32 _prod) public returns(uint32) {
        if (keccak256(abi.encodePacked(participants[_ownerId].participantType)) == keccak256(abi.encodePacked("Manufacturer"))) {   // This function checks if the participant is a manufacturer because only a manufacturer can add a product. using hashing function (keccak256) because you cannot compare strings in solidity. we can also use require
            uint32 productId = product_id++;
            products[productId].modelNumber = _modelNumber;
            products[productId].partNumber = _partNumber;
            products[productId].serialNumber = _serialNumber;
            products[productId].productOwner = participants[_ownerId].participantAddress;
            products[productId].cost = _prod;
            products[productId].mfgTimestamp = uint32(block.timestamp);  // Changed from now to block.timestamp

            return productId;
        }
        return 0;
    }

    // ensures that only the current owner of a product can transfer its ownership. It's like a security check that makes sure the right person is performing the action.
    modifier onlyOwner(uint32 _product_id) {
        require(msg.sender == products[_product_id].productOwner);
        _;     // very important.
    }


    function getProduct(uint32 _product_id) public view returns(string memory, string memory, string memory, address, uint32, uint32) {
        return (products[_product_id].modelNumber, products[_product_id].partNumber, products[_product_id].serialNumber, products[_product_id].productOwner, products[_product_id].cost, products[_product_id].mfgTimestamp);
    }

    function newOwner(uint32 _user1Id, uint32 user2Id, uint32 _prodId) onlyOwner(_prodId) public returns(bool) {
        participant memory p1 = participants[_user1Id];
        participant memory p2 = participants[user2Id];
        uint32 ownership_id = owner_id++;

        if (keccak256(abi.encodePacked(p1.participantType)) == keccak256("Manufacturer") && keccak256(abi.encodePacked(p2.participantType)) == keccak256("Supplier")) {
            ownerships[ownership_id].product_id = _prodId;
            ownerships[ownership_id].owner_id = user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            ownerships[ownership_id].productOwner = p2.participantAddress;
            products[_prodId].productOwner = p2.participantAddress;
            ownershipsByProduct[_prodId].push(ownership_id);     // Changed from productTrack to ownershipsByProduct
            emit TransferOwnership(_prodId);
            
            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Supplier") && keccak256(abi.encodePacked(p2.participantType)) == keccak256("Supplier")) {
            ownerships[ownership_id].product_id = _prodId;
            ownerships[ownership_id].owner_id = user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            ownerships[ownership_id].productOwner = p2.participantAddress;
            products[_prodId].productOwner = p2.participantAddress;
            ownershipsByProduct[_prodId].push(ownership_id);     // Changed from productTrack to ownershipsByProduct
            emit TransferOwnership(_prodId);
            
            return (true);
        }
        else if(keccak256(abi.encodePacked(p1.participantType)) == keccak256("Supplier") && keccak256(abi.encodePacked(p2.participantType)) == keccak256("Consumer")) {
            ownerships[ownership_id].product_id = _prodId;    
            ownerships[ownership_id].owner_id = user2Id;
            ownerships[ownership_id].trxTimeStamp = uint32(block.timestamp);
            ownerships[ownership_id].productOwner = p2.participantAddress;
            products[_prodId].productOwner = p2.participantAddress;
            ownershipsByProduct[_prodId].push(ownership_id);     // Changed from productTrack to ownershipsByProduct
            emit TransferOwnership(_prodId);
            
            return (true);
        }

        return (false);    
    }

    // gets provenance/list of ownerships for a specific product
    function getProvenance(uint32 _prodId) external view returns (uint32[] memory) {
        return ownershipsByProduct[_prodId];    // Changed from productTrack to ownershipsByProduct
    }

    // gets current owner details
    function getOwnership(uint32 _regId) public view returns (uint32,uint32,address,uint32){

        ownership memory r = ownerships[_regId];
        return (r.product_id, r.owner_id, r.productOwner, r.trxTimeStamp);
    }

    // authenticate participant by checking a match in username, password and participant type then return true which is not entirely secure.
    function authenticateParticipant(uint _uid, string memory _uname, string memory _pass, string memory _utype) public view returns(bool) {
        if(keccak256(abi.encodePacked(participants[uint32(_uid)].participantType)) == keccak256(abi.encodePacked(_utype))){
            if(keccak256(abi.encodePacked(participants[uint32(_uid)].userName)) == keccak256(abi.encodePacked(_uname))){
                if(keccak256(abi.encodePacked(participants[uint32(_uid)].password)) == keccak256(abi.encodePacked(_pass))){
                    return true;
                }
            }
        }
        return false;
    }
} 
