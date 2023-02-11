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