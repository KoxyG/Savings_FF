# TimeLockSavings – Audit Summary


## Findings Summary
- High: Incorrect parameter order in reward calculation during withdraw
- Medium: `Deposited` event arguments emitted in wrong order
- Low: Missing explicit “already withdrawn” guard (second call currently reverts via arithmetic underflow)
- Informational: `calculateReward` visibility should be `internal`



## Details
### 1. High — Wrong parameter order in `withdraw`
Code calls `calculateReward(timeElapsed, amount)` instead of `calculateReward(amount, timeElapsed)`, producing incorrect rewards and possible transfer failures.

- Recommendation: use `calculateReward(amount, timeElapsed)`.
- POC:
[`testWithdrawalParameterOrderBug`](https://github.com/KoxyG/Savings_FF/blob/main/test/SavingsTest.t.sol) : Demonstrates incorrect reward calculation causing revert or mismatch.


### 2. Medium — `Deposited` event argument order

Event declares `(user, amount, depositId)` but emission uses `(user, depositId, amount)`, breaking off-chain consumers.
- Recommendation: `emit Deposited(msg.sender, _amount, userDeposits[msg.sender].length - 1);` . 
  

### 3. Low — No explicit double-withdraw guard

The code sets `withdrawn = true` but does not check it; a second call reverts due to arithmetic underflow or anything else. Add clarity and save gas with an explicit guard.

- Recommendation:
Add `require(!userDeposit.withdrawn, "Already withdrawn");`
Optionally set `userDeposit.amount = 0;` at first withdrawal.
  

### 4. Informational — `calculateReward` visibility

`calculateReward` is `public`. Prefer `internal` unless external callers are required, to minimize surface area and hide business logic.