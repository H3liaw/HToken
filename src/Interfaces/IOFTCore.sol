// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IOFTCore
 * @notice Core interface for OFT functionality including KUSD-specific functions
 */
interface IOFTCore {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct representing a send parameter for cross-chain transfers
     */
    struct SendParam {
        uint32 dstEid; // Destination endpoint ID
        bytes32 to; // Recipient address in bytes32 format
        uint256 amountLD; // Amount in local decimals
        uint256 minAmountLD; // Minimum amount in local decimals
        bytes extraOptions; // Additional options
        bytes composeMsg; // Compose message
        bytes oftCmd; // OFT command
    }

    /**
     * @notice Struct representing messaging fees
     */
    struct MessagingFee {
        uint256 nativeFee; // Native fee amount
        uint256 lzTokenFee; // LayerZero token fee amount
    }

    /**
     * @notice Struct representing messaging receipt
     */
    struct MessagingReceipt {
        bytes32 guid; // Globally unique identifier
        uint64 nonce; // Message nonce
        MessagingFee fee; // Messaging fee paid
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when tokens are sent cross-chain
     */
    event OFTSent(
        bytes32 indexed guid,
        uint32 dstEid,
        address indexed fromAddress,
        uint256 amountSentLD,
        uint256 amountReceivedLD
    );

    /**
     * @notice Event emitted when tokens are received cross-chain
     */
    event OFTReceived(
        bytes32 indexed guid,
        uint32 srcEid,
        address indexed toAddress,
        uint256 amountReceivedLD
    );

    /**
     * @notice Event emitted when peer is set
     */
    event PeerSet(uint32 indexed eid, bytes32 indexed peer);

    /**
     * @notice Event emitted when endpoint is updated
     */
    event EndpointSet(address indexed endpoint);

    /*//////////////////////////////////////////////////////////////
                          CORE OFT FUNCTIONS
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
    ) external payable returns (MessagingReceipt memory msgReceipt, bytes memory oftReceipt);

    /**
     * @notice Quote the messaging fee for a send operation
     * @param _sendParam The send parameters
     * @param _payInLzToken Whether to pay in LZ token
     * @return msgFee The messaging fee
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view returns (MessagingFee memory msgFee);

    /**
     * @notice Get the token address
     * @return The token address
     */
    function token() external view returns (address);

    /**
     * @notice Check if a peer is trusted
     * @param _eid The endpoint ID
     * @param _peer The peer address
     * @return Whether the peer is trusted
     */
    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                          MINTING & BURNING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint tokens
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burn tokens
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set a trusted peer for cross-chain communication
     * @param _eid The endpoint ID
     * @param _peer The peer address in bytes32 format
     */
    function setPeer(uint32 _eid, bytes32 _peer) external;

    /**
     * @notice Set the LayerZero endpoint address
     * @param _endpoint The new endpoint address
     */
    function setEndpoint(address _endpoint) external;

    /**
     * @notice Remove a peer
     * @param _eid The endpoint ID to remove
     */
    function removePeer(uint32 _eid) external;

    /*//////////////////////////////////////////////////////////////
                       ROLE MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Grant admin role to an address
     * @param account Address to grant admin role
     */
    function grantAdminRole(address account) external;

    /**
     * @notice Revoke admin role from an address
     * @param account Address to revoke admin role
     */
    function revokeAdminRole(address account) external;

    /**
     * @notice Grant minter role to an address
     * @param account Address to grant minter role
     */
    function grantMinterRole(address account) external;

    /**
     * @notice Revoke minter role from an address
     * @param account Address to revoke minter role
     */
    function revokeMinterRole(address account) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if an address has admin role
     * @param account Address to check
     * @return True if address has admin role
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Check if an address has minter role
     * @param account Address to check
     * @return True if address has minter role
     */
    function isMinter(address account) external view returns (bool);

    /**
     * @notice Get all peers
     * @param eids Array of endpoint IDs to check
     * @return peerAddresses Array of peer addresses
     */
    function getPeers(uint32[] calldata eids) external view returns (bytes32[] memory peerAddresses);

    /**
     * @notice Get peer for specific endpoint
     * @param eid Endpoint ID
     * @return Peer address in bytes32 format
     */
    function peers(uint32 eid) external view returns (bytes32);

    /**
     * @notice Get local endpoint ID
     * @return Local endpoint ID
     */
    function localEid() external view returns (uint32);

    /**
     * @notice Get endpoint address
     * @return Endpoint address
     */
    function endpoint() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                       CROSS-CHAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Handle incoming cross-chain tokens
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
    ) external;
}