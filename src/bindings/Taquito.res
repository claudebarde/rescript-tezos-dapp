type t

module Tz = {
    type t

    @send external get_balance: (t, Tezos.account_address) => promise<Big_number.big_int> = "getBalance"
}

module Operation = {
    type t = {
        @as("opHash") op_hash: string
    }

    @send external confirmation: t => promise<unit> = "confirmation"
    @send external status: t => promise<string> = "status" // pending, applied, unknown, failed, skipped, backtracked
}

module Wallet = {
    type t
    type transfer_operation

    type transfer_param = {
        to: Tezos.account_address,
        amount: float
    }

    @send external transfer: (t, transfer_param) => promise<transfer_operation> = "transfer"
    @send external send: transfer_operation => promise<Operation.t> = "send"
}

@new @module("@taquito/taquito") external tezos_toolkit: string => t = "TezosToolkit"
@send external set_wallet_provider: (t, Beacon_wallet.t) => unit = "setWalletProvider"
@get external tz: t => Tz.t = "tz"
@get external wallet: t => Wallet.t = "wallet"

@module("@taquito/utils") external validate_address: Tezos.account_address => bool = "validateAddress"