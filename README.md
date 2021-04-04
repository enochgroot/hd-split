# HDSplit

This contract creates an immutable list of addresses and percentages and accepts
any token or ETH sent to the contract.  It has one function, `push()` that allows
anyone to push funds to each address in the list, along with their corresponding
percentages.

# Building and Testing

Install [dapp.tools](https://dapp.tools)

## Install deps
```
dapp update
```

## Build
```
make clean
make
```

## Test
```
make test
```