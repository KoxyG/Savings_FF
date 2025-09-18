## Foundry

# TimeLockSavings – Audit Summary

## Findings Summary

- High: Incorrect parameter order in reward calculation during withdraw
- Medium: `Deposited` event arguments emitted in wrong order
- Low: Missing explicit “already withdrawn” guard (second call currently reverts via arithmetic underflow)
- Informational: `calculateReward` visibility should be `internal`
- Informational: Integer truncation to 0 for sub-wei rewards is by design
- Not an issue: Per-user `depositId` reuse (e.g., both users have id 0); cross-user withdrawal not possible; reentrancy out of scope with trusted ERC20

## Details

### High — Wrong parameter order in `withdraw`

Code calls `calculateReward(timeElapsed, amount)` instead of `calculateReward(amount, timeElapsed)`, producing incorrect rewards and possible transfer failures.

Recommendation: use `calculateReward(amount, timeElapsed)`.
POC: 


### Medium — `Deposited` event argument order

Event declares `(user, amount, depositId)` but emission uses `(user, depositId, amount)`, breaking off-chain consumers.

Recommendation: `emit Deposited(msg.sender, _amount, userDeposits[msg.sender].length - 1);`


### Low — No explicit double-withdraw guard

The code sets `withdrawn = true` but does not check it; a second call reverts due to arithmetic underflow or anything else. Add clarity and save gas with an explicit guard.

Recommendation:
- Add `require(!userDeposit.withdrawn, "Already withdrawn");`
- Optionally set `userDeposit.amount = 0;` at first withdrawal.
  

### Informational — `calculateReward` visibility

`calculateReward` is `public`. Prefer `internal` unless external callers are required, to minimize surface area and hide business logic.

### Informational — Integer truncation

With 18 decimals, rewards are in wei. Values < 1 wei truncate to 0 (by design). Values like 0.001 token (1e15 wei) are representable.

## Proofs of Concept (Foundry)

- `testWithdrawalParameterOrderBug`: Demonstrates incorrect reward calculation causing revert or mismatch.
- `testDoubleWithdrawReverts`: First withdraw succeeds; second withdraw on the same `depositId` reverts (arithmetic underflow). Add explicit guard for clarity.

## Not Issues

- Authorization: Users cannot withdraw other users’ deposits; IDs are per-user, and lookups use `userDeposits[msg.sender]`.
- Reentrancy: Out of scope given a single trusted ERC20. For defense-in-depth with arbitrary tokens, consider a reentrancy guard and SafeERC20.

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
