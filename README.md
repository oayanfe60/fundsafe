```markdown
# FundSafe - Decentralized DAO Treasury Management

A Clarity smart contract for Stacks that implements a decentralized autonomous organization (DAO) treasury system with member governance, spending proposals, and reputation tracking.

## Features

### Core Treasury Management
- **Deposit STX**: Members can deposit STX into the shared treasury
- **Spending Proposals**: Create proposals to spend treasury funds with recipient and amount
- **Approval Workflow**: Members vote to approve or reject spending proposals
- **Threshold-Based Execution**: Proposals execute automatically once reaching the approval threshold
- **Treasury Balance Tracking**: Real-time monitoring of available funds

### Member Management
- **Member Registration**: Add and remove DAO members
- **Access Control**: Only members can participate in governance
- **Membership Status**: Query member status at any time
- **Quit Function**: Members can voluntarily leave the DAO

### Governance & Reputation
- **Reputation System**: Members earn reputation for active participation
- **Approval Threshold**: Configurable minimum approvals required for execution
- **Dynamic Settings**: Update governance parameters as needed
- **Reputation Tracking**: View member contribution history

### Utility Functions
- **Tip**: Reward active members from the treasury
- **Burn**: Permanently reduce treasury balance (deflation)
- **Read-Only Queries**: Access all contract data without state changes

## Contract Functions

### Public Functions
| Function | Parameters | Description |
|----------|-----------|-------------|
| `deposit` | `amount: uint` | Deposit STX into treasury |
| `add-member` | `new-member: principal` | Add a new DAO member |
| `remove-member` | `member: principal` | Remove a member |
| `create-spend-proposal` | `recipient: principal`, `amount: uint` | Create spending proposal |
| `approve-proposal` | `proposal-id: uint` | Approve a proposal |
| `reject-proposal` | `proposal-id: uint` | Reject a proposal |
| `execute-proposal` | `proposal-id: uint` | Execute approved proposal |
| `tip` | `member: principal`, `amount: uint` | Reward a member |
| `quit` | - | Leave the DAO |
| `burn` | `amount: uint` | Reduce treasury permanently |
| `update-threshold` | `new-threshold: uint` | Change approval threshold |

### Read-Only Functions
| Function | Parameters | Returns |
|----------|-----------|---------|
| `is-dao-member` | `user: principal` | `bool` |
| `get-treasury-balance` | - | `uint` |
| `get-proposal` | `proposal-id: uint` | `proposal` object |
| `get-reputation` | `user: principal` | `uint` |

## Error Codes
- `ERR-AUTH (u300)`: Authorization failed - not a member
- `ERR-NOT-FOUND (u301)`: Proposal not found
- `ERR-STATE (u302)`: Invalid state for operation
- `ERR-BALANCE (u303)`: Insufficient balance

## Usage Example

```clarity
;; Deposit 1000 STX
(deposit u1000000000)

;; Create a spending proposal
(create-spend-proposal 'SP2ABC recipient-address u500000000)

;; Approve the proposal
(approve-proposal u1)

;; Execute when threshold is met
(execute-proposal u1)

;; Reward a member
(tip 'SP3XYZ u10000000)

;; Update approval threshold
(update-threshold u3)
```

## Requirements
- Stacks blockchain environment
- Clarity contract support
- STX tokens for transactions

## License
MIT
