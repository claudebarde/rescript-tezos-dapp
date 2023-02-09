let ctez_address: Tezos.fa1_2_token = { address: "KT1Q4ecagDAmqiY3ajvtwfNZyChWy86W7pzb", decimals: 6 }
let kusd_address: Tezos.fa1_2_token = { address: "KT1AfUy48JvqVvtcXKxBDy1guDTJSWd1n8Uv", decimals: 18 }
let uusd_address: Tezos.fa2_token = { address: "KT19RSC3s5EzvSTquHnav6JNzgb6ngoh1YUh", token_id: 0, decimals: 12 }

let update_amount = (amt: string, user_xtz_balance: option<int>): (option<float>, bool) => {
    switch amt->Belt.Float.fromString {
    | None => (None, false)
    | Some(amount) => {
        if amount === 0.0 {
            (None, false)
        } else {
            switch user_xtz_balance {
                | None => (None, false)
                | Some(balance) => 
                    // displays error
                    let has_error =
                        if balance->Belt.Int.toFloat < amount *. 1_000_000.0 {
                            true
                        } else {
                            false
                        }
                    (Some(amount), has_error)
            }
        }
    }
    }
}