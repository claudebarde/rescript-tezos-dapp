open Types

type t = tezos
    
type account_address = string
type contract_address = string
type fa1_2_token = {
    address: string,
    decimals: int
}
type fa2_token = {
    address: string,
    token_id: int,
    decimals: int
}

type fa1_2_storage = {
    tokens: big_map,
    total_supply: Big_number.big_int
}

type fa2_storage = {
    ledger: big_map,
}

type fa2_transfer_tx = { to_: account_address, token_id: int, quantity: float }
type fa2_transfer_param = {
    from_: account_address,
    tx: array<fa2_transfer_tx>
}