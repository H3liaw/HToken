// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ERC20 } from "solady/tokens/ERC20.sol";
import { OwnableRoles } from "solady/auth/OwnableRoles.sol";
import { IOFTCore } from "./Interfaces/IOFTCore.sol";
import {
    ILayerZeroEndpointV2,
    MessagingParams,
    MessagingReceipt,
    Origin,
    MessagingFee as LZMessagingFee
} from "./Interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title HUSD
 * @notice OFT-compatible token with role-based access control using Solady
 * @dev Implements ERC20, OFT functionality, and OwnableRoles from Solady
 */
contract HUSDToken is ERC20, OwnableRoles, IOFTCore {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    
    uint256 public constant ADMIN_ROLE = _ROLE_0;
    uint256 public constant MINTER_ROLE = _ROLE_1;
    uint256 public constant BURNER_ROLE = _ROLE_2;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error OFTInvalidEndpoint(uint32 eid);
    error OFTInsufficientBalance(uint256 balance, uint256 needed);
    error OFTInvalidPeer(uint32 eid, bytes32 peer);
    error UnauthorizedAccount(address account, uint256 neededRole);
    error ZeroAddressNotAllowed();
    error PeerNotSet(uint32 eid);


    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Token metadata
    string private _name;
    string private _symbol;

    // OFT Storage
    mapping(uint32 => bytes32) public peers; // eid => peer address
    uint32 public localEid;
    address public endpoint;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        if (!hasAnyRole(msg.sender, ADMIN_ROLE) && msg.sender != owner()) {
            revert UnauthorizedAccount(msg.sender, ADMIN_ROLE);
        }
        _;
    }

    modifier onlyMinter() {
        if (!hasAnyRole(msg.sender, MINTER_ROLE) && msg.sender != owner()) {
            revert UnauthorizedAccount(msg.sender, MINTER_ROLE);
        }
        _;
    }

    modifier onlyBurner() {
        if (!hasAnyRole(msg.sender, BURNER_ROLE) && msg.sender != owner()) {
            revert UnauthorizedAccount(msg.sender, BURNER_ROLE);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address minter_,
        address burner_,
        uint32 localEid_,
        address endpoint_
    ) {
        _name = name_;
        _symbol = symbol_;
        localEid = localEid_;
        endpoint = endpoint_;

        // Initialize owner
        _initializeOwner(owner_);
        
        // Grant initial admin role (only owner can do this)
        if (minter_ != address(0)) {
            _grantRoles(minter_, MINTER_ROLE);
        }

        // Grant initial burner role (only owner can do this)
        if (burner_ != address(0)) {
            _grantRoles(burner_, BURNER_ROLE);
        }
        
    }

    /*//////////////////////////////////////////////////////////////
                           ERC20 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                          MINTING & BURNING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens - only callable by minter or owner
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyMinter {
        if (to == address(0)) revert ZeroAddressNotAllowed();
        _mint(to, amount);
    }

    /**
     * @notice Burn tokens - only callable by minter or owner
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyBurner {
        if (from == address(0)) revert ZeroAddressNotAllowed();
        _burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////
                          OFT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Send tokens to another chain
     * @param _sendParam The send parameters
     * @param _fee The messaging fee
     * @param _refundAddress Address to receive any refund
     * @return msgReceipt The messaging receipt
     * @return oftReceipt The OFT receipt
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable override returns (MessagingReceipt memory msgReceipt, bytes memory oftReceipt) {
        // Check if peer exists
        if (peers[_sendParam.dstEid] == bytes32(0)) {
            revert OFTInvalidPeer(_sendParam.dstEid, bytes32(0));
        }

        // Check sender balance
        if (balanceOf(msg.sender) < _sendParam.amountLD) {
            revert OFTInsufficientBalance(balanceOf(msg.sender), _sendParam.amountLD);
        }

        // Burn tokens from sender
        _burn(msg.sender, _sendParam.amountLD);

        // Create message receipt
        msgReceipt = MessagingReceipt({
            guid: keccak256(abi.encodePacked(block.timestamp, msg.sender, _sendParam.dstEid)),
            nonce: uint64(block.number),
            fee: _fee
        });

        // Emit event
        emit OFTSent(
            msgReceipt.guid,
            _sendParam.dstEid,
            msg.sender,
            _sendParam.amountLD,
            _sendParam.amountLD
        );
    }

    /**
     * @notice Get the token address
     * @return The token address
     */
    function token() external view override returns (address) {
        return address(this);
    }

    /**
     * @notice Check if a peer is trusted
     * @param _eid The endpoint ID
     * @param _peer The peer address
     * @return Whether the peer is trusted
     */
    function isPeer(uint32 _eid, bytes32 _peer) external view override returns (bool) {
        return peers[_eid] == _peer;
    }

    /**
     * @notice Internal function to quote the messaging fee
     * @param _dstEid The destination endpoint ID
     * @param _message The message to send
     * @param _options The options for the send operation
     * @return msgFee The messaging fee
     */
    function _quoteSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options
    ) internal view returns (IOFTCore.MessagingFee memory) {
        LZMessagingFee memory fee = ILayerZeroEndpointV2(endpoint).quote(
            MessagingParams(_dstEid, _getPeerOrRevert(_dstEid), _message, _options, false), address(this)
        );
        return IOFTCore.MessagingFee(fee.nativeFee, fee.lzTokenFee);
    }

    /**
     * @notice Quote the messaging fee for a send operation
     * @param _sendParam The send parameters
     * @return msgFee The messaging fee
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool 
    ) external view override returns (MessagingFee memory) {
        bytes memory message = abi.encode(_sendParam.to, _sendParam.amountLD);
        bytes memory options = abi.encode(_sendParam.extraOptions, _sendParam.composeMsg, _sendParam.oftCmd);
        return _quoteSend(_sendParam.dstEid, message, options);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set a trusted peer for cross-chain communication
     * @param _eid The endpoint ID
     * @param _peer The peer address in bytes32 format
     */
    function setPeer(uint32 _eid, bytes32 _peer) external onlyAdmin {
        peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Set the LayerZero endpoint address
     * @param _endpoint The new endpoint address
     */
    function setEndpoint(address _endpoint) external onlyAdmin {
        if (_endpoint == address(0)) revert ZeroAddressNotAllowed();
        endpoint = _endpoint;
        emit EndpointSet(_endpoint);
    }

    /**
     * @notice Remove a peer
     * @param _eid The endpoint ID to remove
     */
    function removePeer(uint32 _eid) external onlyAdmin {
        delete peers[_eid];
        emit PeerSet(_eid, bytes32(0));
    }

    /*//////////////////////////////////////////////////////////////
                       ROLE MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Grant admin role to an address
     * @param account Address to grant admin role
     */
    function grantAdminRole(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddressNotAllowed();
        _grantRoles(account, ADMIN_ROLE);
    }

    /**
     * @notice Revoke admin role from an address
     * @param account Address to revoke admin role
     */
    function revokeAdminRole(address account) external onlyOwner {
        _removeRoles(account, ADMIN_ROLE);
    }

    /**
     * @notice Grant minter role to an address
     * @param account Address to grant minter role
     */
    function grantMinterRole(address account) external onlyAdmin {
        if (account == address(0)) revert ZeroAddressNotAllowed();
        _grantRoles(account, MINTER_ROLE);
    }

    /**
     * @notice Revoke minter role from an address
     * @param account Address to revoke minter role
     */
    function revokeMinterRole(address account) external onlyAdmin {
        _removeRoles(account, MINTER_ROLE);
    }


    /**
     * @notice Grant burner role to an address
     * @param account Address to grant burner role
     */
    function grantBurnerRole(address account) external onlyAdmin {
        _grantRoles(account, BURNER_ROLE);
    }

    /**
     * @notice Revoke burner role from an address
     * @param account Address to revoke burner role
     */
    function revokeBurnerRole(address account) external onlyAdmin {
        _removeRoles(account, BURNER_ROLE);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

        /// @notice Gets peer for endpoint or reverts
    function _getPeerOrRevert(uint32 _eid) internal view returns (bytes32) {
        bytes32 peer = peers[_eid];
        if (peer == bytes32(0)) revert PeerNotSet(_eid);
        return peer;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if an address has admin role
     * @param account Address to check
     * @return True if address has admin role
     */
    function isAdmin(address account) external view returns (bool) {
        return hasAnyRole(account, ADMIN_ROLE) || account == owner();
    }

    /**
     * @notice Check if an address has minter role
     * @param account Address to check
     * @return True if address has minter role
     */
    function isMinter(address account) external view returns (bool) {
        return hasAnyRole(account, MINTER_ROLE) || account == owner();
    }


    /**
     * @notice Check if an address has burner role
     * @param account Address to check
     * @return True if address has burner role
     */
    function isBurner(address account) external view returns (bool) {
        return hasAnyRole(account, BURNER_ROLE) || account == owner();
    }

    /**
     * @notice Get all peers
     * @param eids Array of endpoint IDs to check
     * @return peerAddresses Array of peer addresses
     */
    function getPeers(uint32[] calldata eids) external view returns (bytes32[] memory peerAddresses) {
        peerAddresses = new bytes32[](eids.length);
        for (uint256 i = 0; i < eids.length; i++) {
            peerAddresses[i] = peers[eids[i]];
        }
    }

    /*//////////////////////////////////////////////////////////////
                       CROSS-CHAIN RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Handle incoming cross-chain tokens (simplified LayerZero receive)
     * @param _srcEid Source endpoint ID
     * @param _sender Sender address in bytes32 format
     * @param _nonce Message nonce
     * @param _payload Message payload containing recipient and amount
     */
    function lzReceive(
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes calldata _payload
    ) external {
        
        if (peers[_srcEid] != _sender) {
            revert OFTInvalidPeer(_srcEid, _sender);
        }

        (address to, uint256 amount) = abi.decode(_payload, (address, uint256));
        
        if (to == address(0)) revert ZeroAddressNotAllowed();
        
        _mint(to, amount);

        bytes32 guid = keccak256(abi.encodePacked(_srcEid, _sender, _nonce));
        
        emit OFTReceived(guid, _srcEid, to, amount);
    }


}