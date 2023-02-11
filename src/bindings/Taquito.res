open Types

type t = taquito

module Tz = {
    type t

    @send external get_balance: (t, Tezos.account_address) => promise<Big_number.big_int> = "getBalance"
}

module Operation = {
    type t = {
        @as("opHash") op_hash: string
    }

    type status = [#pending | #applied | #unknown | #failed | #skipped | #backtracked]

    @send external confirmation: t => promise<unit> = "confirmation"
    @send external status: t => promise<status> = "status"
}

module Big_map = {
    type t = big_map

    @send external get: (t, 'a) => promise<Js.Nullable.t<'b>> = "get"
}

module ContractAbstraction = {
    type t

    @send external storage: t => promise<'a> = "storage"
}

module Wallet = {
    type t
    type transfer_operation

    type transfer_param = {
        to: Tezos.account_address,
        amount: float
    }

    @send external at: (t, Tezos.contract_address) => promise<ContractAbstraction.t> = "at"
    @send external transfer: (t, transfer_param) => promise<transfer_operation> = "transfer"
    @send external send: transfer_operation => promise<Operation.t> = "send"
}

@new @module("@taquito/taquito") external tezos_toolkit: string => t = "TezosToolkit"
@send external set_wallet_provider: (t, Beacon_wallet.t) => unit = "setWalletProvider"
@get external tz: t => Tz.t = "tz"
@get external wallet: t => Wallet.t = "wallet"

@module("@taquito/utils") external validate_address: Tezos.account_address => bool = "validateAddress"
