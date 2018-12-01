pragma solidity ^ 0.4 .7;

contract owned {

    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Database is owned {

    // addresses of the Products referenced in this database
    address[] public products;

    // sturuct to hold the products owned by a handler and the handler info 
    struct HandlerProducts {
        // Addresses of products owned by Handler
        address[] _ownedProducts;
        // Name of the owner
        string _handlerName;
        // Information about the owner
        string _additionalHandlerInfo;
    }

    // Addresses  of all the handlers
    address[] public handlers;

    // Relates a handler address to the handler products and handler info
    mapping(address => HandlerProducts) productByHandlers;
    
    // Map verified addresses
    mapping (address => bool) public verified;
    
    modifier onlyVerified{
        require(verified[msg.sender]);
        _;
    }

    function Database() public {}

    function () public {
        // If anyone wants to send Ether to this contract, the transaction gets rejected
        throw;
    }
    
    function verifyHandler(address handler) external onlyOwner{
        verified[handler] = true;
    }
    
    function removeVerifiedHandler(address handler) external onlyOwner{
        verified[handler] = false;
    }

    /* Function to add a product reference
     productAddress address of the product */
    function storeProductReference(address _productAddress, address _handler, string _handlerName, string _handlerInfo) public {
        products.push(_productAddress);

        if (handlers.length == 0) {
            handlers.push(_handler);
            addProductForHandler(_handler, _handlerName, _handlerInfo, _productAddress);
        } else {
            if (!isHandlerPresent(_handler)) {
                handlers.push(_handler);
                addProductForHandler(_handler, _handlerName, _handlerInfo, _productAddress);
            } else {
                addProductForHandler(_handler, _handlerName, _handlerInfo, _productAddress);
            }
        }
    }

    /* Function to check if the handler already
     exists in the database or not*/
    function isHandlerPresent(address handlerAddr) view private returns(bool) {
        for (uint i = 0; i < handlers.length; i++) {
            if (handlers[i] == handlerAddr) {
                return true;
            }
        }
    }

    /* Function to add a product and the product information */
    function addProductForHandler(address _handlerAddr, string _handlerName, string _handlerInfo, address _productAddr) private {
        productByHandlers[_handlerAddr]._ownedProducts.push(_productAddr);
        productByHandlers[_handlerAddr]._handlerName = _handlerName;
        productByHandlers[_handlerAddr]._additionalHandlerInfo = _handlerInfo;
    }

    /* Function to list all the products present
     in the database*/
    function getAllProducts() view public returns(address[]) {
        return products;
    }
    
    function getAllHandlers() view public returns(address[]) {
        return handlers;
    }

    /* Function to list all the products owened 
       by a handler present in the database*/
    function getHandler(address _address) view public returns(string, string, address[]) {
        return (productByHandlers[_address]._handlerName, productByHandlers[_address]._additionalHandlerInfo, productByHandlers[_address]._ownedProducts);
    }
}


contract Product {
    // Reference to its database contract.
    address public DATABASE_CONTRACT;
    // Reference to its product category.
    address public PRODUCT_CATEGORY;
    // Refence to its owner
    address public owner;
    // Handler's name
    string public ownerName;
    // Handler's info
    string public ownerInfo;


    // This struct represents an action realized by a handler on the product.
    struct Action {
        // description of the action.
        string description;
        // address of the product's owner
        address owner;
        // Instant of time when the Action is done.
        uint timestamp;
        // Block when the Action is done.
        uint blockNumber;
    }

    // if the Product is consumed the transaction can't be done.
    modifier notConsumed {
        if (isConsumed)
            throw;
        _;
    }

    // addresses of the products which are built by this Product.
    address[] public childProducts;

    // indicates if a product has been consumed or not.
    bool public isConsumed;

    // indicates the name of a product.
    string public name;

    // Additional information about the Product, generally as a JSON object
    string public additionalInformation;

    // all the actions which have been applied to the Product.
    Action[] public actions;

    /////////////////
    // Constructor //
    /////////////////

    /* _name The name of the Product
       _additionalInformation Additional information about the Product
       _ownerProducts Addresses of the owner of the Product.
       _DATABASE_CONTRACT Reference to its database contract
       _PRODUCT_CATEGORY Reference to its product factory */
    function Product(string _name, string _additionalInformation, address _DATABASE_CONTRACT,
        address _PRODUCT_CATEGORY, string _handlerName, string _handlerInfo) public {
        name = _name;
        isConsumed = false;
        additionalInformation = _additionalInformation;

        DATABASE_CONTRACT = _DATABASE_CONTRACT;
        PRODUCT_CATEGORY = _PRODUCT_CATEGORY;
        owner = msg.sender;
        ownerName = _handlerName;
        ownerInfo = _handlerInfo;

        Action memory creation;
        creation.description = "Product creation";
        creation.owner = msg.sender;
        creation.timestamp = now;
        creation.blockNumber = block.number;

        actions.push(creation);

        Database database = Database(DATABASE_CONTRACT);
        database.storeProductReference(this, owner, _handlerName, _handlerInfo);
    }

    function () public {
        // If anyone wants to send Ether to this contract, the transaction gets rejected
        throw;
    }

    /* Function to add an Action to the product.
       _description The description of the Action.
       _newProductNames In case that this Action creates more products from
              this Product, the names of the new products should be provided here.
       _newProductsAdditionalInformation In case that this Action creates more products from
              this Product, the additional information of the new products should be provided here.
       _consumed True if the product becomes consumed after the action. */
    //   function addAction(bytes32 description, bytes32[] newProductsNames, bytes32[] newProductsAdditionalInformation, bool _consumed) notConsumed {
    //     if (newProductsNames.length != newProductsAdditionalInformation.length) throw;

    //     Action memory action;
    //     action.handler = msg.sender;
    //     action.description = description;
    //     action.timestamp = now;
    //     action.blockNumber = block.number;

    //     actions.push(action);

    //     ProductFactory productFactory = ProductFactory(PRODUCT_CATEGORY);

    //     for (uint i = 0; i < newProductsNames.length; ++i) {
    //       address[] memory ownerProducts = new address[](1);
    //       ownerProducts[0] = this;
    //       productFactory.createProduct(newProductsNames[i], newProductsAdditionalInformation[i], ownerProducts, DATABASE_CONTRACT);
    //     }

    //     isConsumed = _consumed;
    //   }

    /* Function to merge some products to build a new one.
       otherProducts addresses of the other products to be merged.
       newProductsName Name of the new product resulting of the merge.
       newProductAdditionalInformation Additional information of the new product resulting of the merge.*/
    //   function merge(address[] otherProducts, bytes32 newProductName, bytes32 newProductAdditionalInformation) notConsumed {
    //     ProductFactory productFactory = ProductFactory(PRODUCT_CATEGORY);
    //     address newProduct = productFactory.createProduct(newProductName, newProductAdditionalInformation, otherProducts, DATABASE_CONTRACT);

    //     this.collaborateInMerge(newProduct);
    //     for (uint i = 0; i < otherProducts.length; ++i) {
    //       Product prod = Product(otherProducts[i]);
    //       prod.collaborateInMerge(newProduct);
    //     }
    //   }

    /* Function to collaborate in a merge with some products to build a new one.
       newProductsAddress Address of the new product resulting of the merge. */
    function collaborateInMerge(address newProductAddress) public notConsumed {
        childProducts.push(newProductAddress);

        Action memory action;
        action.owner = this;
        action.description = "Collaborate in merge";
        action.timestamp = now;
        action.blockNumber = block.number;

        actions.push(action);

        this.consume();
    }

    /* Function to consume the Product */
    function consume() public notConsumed {
        isConsumed = true;
    }
}


contract ProductFactory {

    /////////////////
    // Constructor //
    /////////////////

    function ProductFactory() public {}

    function () public {
        // If anyone wants to send Ether to this contract, the transaction gets rejected
        throw;
    }

    /* Function to create a Product
       _name The name of the Product
       _additionalInformation Additional information about the Product
       _ownerProducts Addresses of the owner of the Product.
       _DATABASE_CONTRACT Reference to its database contract */
    function createProduct(string _name, string _additionalInformation, address DATABASE_CONTRACT, string _handlerName, string _handlerInfo) public returns(address) {
        return new Product(_name, _additionalInformation, DATABASE_CONTRACT, this, _handlerName, _handlerInfo);
    }
}
