open Types

type t = taquito

module Tz = {
    type t

    @send external get_balance: (t, Tezos.account_address) => promise<Big_number.big_float> = "getBalance"
}

module Operation = {
    type t = {
        // TODO: "opHash" is for "transfer" operation, contract calls have "hash"
        @as("opHash") op_hash: string,
        hash: string
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

    module Contract_call = {
        type t = taquito_contract_call

        type options_val = { amount: int, mutez: bool }
        type options = option<options_val>

        @send external send: (t, options) => promise<Operation.t> = "send"
    }
    
    module Ctez_entrypoints = {
        type t

        @send external transfer: (t, ~from: Tezos.account_address, ~to: Tezos.account_address, ~value: float) => taquito_contract_call = "transfer"
        @send external approve: (t, ~spender: Tezos.account_address, ~value: int) => taquito_contract_call = "approve"
    }

    module Kusd_entrypoints = {
        type t

        @send external transfer: (t, ~from: Tezos.account_address, ~to: Tezos.account_address, ~value: float) => taquito_contract_call = "transfer"
        @send external approve: (t, ~spender: Tezos.account_address, ~value: int) => taquito_contract_call = "approve"
    }

    module Uusd_entrypoints = {
        type t        

        @send external transfer: (t, array<Tezos.fa2_transfer_param>) => taquito_contract_call = "transfer"
    }

    @get external ctez_methods: t => Ctez_entrypoints.t = "methods"
    @get external kusd_methods: t => Kusd_entrypoints.t = "methods"
    @get external uusd_methods: t => Uusd_entrypoints.t = "methods"
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
