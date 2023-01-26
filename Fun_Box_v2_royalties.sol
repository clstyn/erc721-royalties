// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol";
import "rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "rarible/royalties/contracts/LibPart.sol";
import "rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract FunBoxV2 is ERC721Enumerable, Ownable, RoyaltiesV2Impl, ERC2981 {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";

  uint256 public cost = 0.001 ether;

  uint256 public maxSupply = 15;

  uint256 public maxMintAmount = 1;

  bool public paused = false;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
   
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }


    //configure royalties for Rariable
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }


    // //configure royalties for Mintable using the ERC2981 standard
    // function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    //     //use the same royalties that were saved for Rariable
    //     LibPart.Part[] memory _royalties = royalties[_tokenId];
    //     if(_royalties.length > 0) {
    //     return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    //     }
    //     return (address(0), 0);
    // }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if(interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }

        return super.supportsInterface(interfaceId);
    }

}