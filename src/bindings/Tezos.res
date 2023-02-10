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
    tokens: Taquito.Big_map.t,
    total_supply: Big_number.t
}

type fa2_storage = {
    ledger: Taquito.Big_map.t,
}