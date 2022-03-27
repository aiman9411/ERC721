// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// @notice Library to check whether address is contract
library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// @dev Interface to ensure receiving contract implements IERC721Receiver 
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// @dev Interface to detect and publish what interface smart contract implement
interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// @dev Interface of ERC721
interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract ERC721 is IERC721 {
    // @dev Using library address to ensure type of recipient contract
    using Address for address;

    // @notice Events to log transaction
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // @notice Mapping token ID to owner address
    mapping(uint => address) internal _owner;

    // @notice Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // @notice Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // @notice Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApproval;

    // @notice Function to check interface used in contract
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return 
            interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // @notice Function to check balance of token for owner
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "owner=zero address");
        return _balances[owner];
    }

    // @notice Function to check owner of token
    function ownerOf(uint tokenId) public view override returns (address) {
        return _owner[tokenId];
    }

    // @notice Function to approve all 
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApproval[owner][operator];
    }

    // @notice Function to set approval for all
    function setApprovalForAll(address operator, bool _approved) external override {
        _operatorApproval[msg.sender][operator] = _approved;
    }

    // @notice Function to view approved address for the token
    function getApproved(uint tokenId) external view override returns (address operator) {
        require(_owner[tokenId] != address(0), "token does not exist");
        return _tokenApprovals[tokenId];
    }

    // @notice Function to approve spender for token
    function _approve(address owner, address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function approve(address _to, uint tokenId) external override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _operatorApproval[owner][msg.sender], "not owner nor approved for all");
        _approve(owner, _to, tokenId);
    }

    // @notice Function view approved address or owner
    function _isApprovedOrOwner(address owner, address spender, uint tokenId) private view returns (bool) {
        return (spender == owner || _tokenApprovals[tokenId] == spender || _operatorApproval[owner][spender]);
    }

    // @notice Function to transfer token to new owner
    function _transfer(address owner, address from, address to, uint tokenId) private {
        require(from == owner, "not owner");
        require(to != address(0), "transfer to the zero address");
        _approve(owner, address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }

    // @notice Function to transfer token by spender
    function transferFrom(address from, address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner, msg.sender, tokenId), "not owner nor approved");
        _transfer(owner, from, to, tokenId);
    }

    // @notice Function to check ERC721 receiver interface
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            return IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) == IERC721Receiver.onERC721Received.selector;
        } else {
            return true;
        }
    } 

    // @notice Function to allow safe transfer
    function _safeTransfer(address owner, address from, address to, uint tokenId, bytes memory _data) private  {
        require(_checkOnERC721Received(owner, to, tokenId, _data));
        _transfer(owner, from, to, tokenId);
    }

    // @notice Function to allow safe transfer from
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner, msg.sender, tokenId), "not owner nor approved");
        _safeTransfer(owner, from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // @notice Function to mint token
    function mint(address to, uint tokenId) external {
        require(to != address(0), "Mint to zero address");
        require(_owner[tokenId] == address(0), "token already minted");
        _balances[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    // @notice Function to burn token
    function burn(uint tokenId) external {
        address owner = _owner[tokenId];
        _approve(owner, address(0), tokenId);
        _balances[owner] -= 1;
        delete _owner[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }


}
