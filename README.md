# TimeLockSavings – Full Security Audit Report

## Executive Summary
- The review identified one high-severity issue causing incorrect reward payouts during withdrawals, one medium-severity event-argument ordering issue, and two low/informational issues.
- The high-severity issue can lead to withdrawal failures or mismatched payouts due to misordered parameters in reward calculation.
- Remediations are straightforward and primarily involve correcting parameter order, event emission arguments, and adding explicit guards/visibility.

## Scope
- **Contracts**
  - `src/Savings.sol` (`TimeLockSavings`)
- **Tests** (for PoC validation)
  - `test/SavingsTest.t.sol`
- **Environment**: Foundry, Solidity 0.8.x, custom `MockERC20` for tests.


## Findings Summary
- **High**: Incorrect parameter order in reward calculation during withdraw
- **Medium**: `Deposited` event arguments emitted in wrong order
- **Low**: Missing explicit "already withdrawn" guard (second call currently reverts via arithmetic underflow)
- **Informational**: `calculateReward` visibility should be `internal`

## Detailed Findings

### 1. High — Wrong parameter order in `withdraw` reward calculation
- **Description**: In the normal withdrawal branch, `calculateReward` is invoked with parameters swapped, leading to incorrect reward amounts. This can cause payout mismatches or revert conditions due to insufficient balance when the computed total exceeds available funds.

```82:85:src/Savings.sol
        } else {
            // Normal withdrawal with rewards
            uint256 reward = calculateReward(timeElapsed, amount);
            uint256 totalAmount = amount + reward;
```

- **Correct usage elsewhere confirms intended parameter order**:

```134:135:src/Savings.sol
    uint256 reward = calculateReward(userDeposit.amount, timeElapsed);
```

- **Impact**:
  - Users can experience failed withdrawals or incorrect payouts
  - Accounting variables (`totalRewardsPaid`) may become inconsistent with the intended design

- **Likelihood**: High. The path is executed by any user after the minimum lock period.

- **Recommendation**: Replace `calculateReward(timeElapsed, amount)` with `calculateReward(amount, timeElapsed)`.

- **PoC**: See the test `testWithdrawalParameterOrderBug` which demonstrates the discrepancy and failure condition. Reference: [`test/SavingsTest.t.sol`](https://github.com/KoxyG/Savings_FF/blob/main/test/SavingsTest.t.sol)

### 2. Medium — `Deposited` event argument order mismatch
- **Description**: The `Deposited` event is declared as `(user, amount, depositId)` but is emitted as `(user, depositId, amount)`, which can break indexers, analytics, or any off-chain consumers relying on the event schema.

```33:35:src/Savings.sol
    event Deposited(address indexed user, uint256 amount, uint256 depositId);
```

```57:58:src/Savings.sol
    emit Deposited(msg.sender, userDeposits[msg.sender].length - 1, _amount);