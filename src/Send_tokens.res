@react.component
let make = (
        ~tezos: option<Taquito.t>,
        ~user_address: option<string>,
    ) => {
    let (amount, set_amount) = React.useState(() => None)
    let (recipient, set_recipient) = React.useState(() => None)
    let (transaction_status, set_transaction_status) = React.useState(() => #unknown)
    let (ctez_balance, set_ctez_balance) = React.useState(() => None)
    let (kusd_balance, set_kusd_balance) = React.useState(() => None)
    let (uusd_balance, set_uusd_balance) = React.useState(() => None)

    let fetch_token_balance = async (token: string): promise<unit> => {
        switch token {
            | "ctez" if ctez_balance === None => {
                let balance = 
                    switch tezos {
                        | None => {
                            Js.log("TezosToolkit hasn't been initialized")

                            None
                        }
                        | Some(tezos) => {
                            open Taquito
                            open Wallet
                            open ContractAbstraction

                            switch await (await tezos->wallet->at(Utils.ctez_address.address))->storage {
                                | (storage: Tezos.fa1_2_storage) => {
                                    switch user_address {
                                    | None => {
                                        Js.log("User address is unknown")

                                        None
                                    }
                                    | Some(address) => {
                                        switch await storage.tokens->Big_map.get(address) {
                                            | (balance: Js.Nullable.t<Big_number.big_int>) => {
                                                switch balance->Js.Nullable.toOption {
                                                    | None => None
                                                    | Some(blnc) => blnc->Big_number.to_int->Some
                                                }
                                            }
                                            | exception JsError(_) => {
                                                let _ = Js.log("Unable to fetch the user's Ctez balance")

                                                None
                                            }
                                        }
                                    }
                                }
                                }
                                | exception JsError(_) => {
                                    Js.log("Unable to fetch the storage of the Ctez contract")

                                    None
                                }
                            }
                        }
                    }
                let _ = set_ctez_balance(_ => balance)
                Js.Promise.resolve(())
            }
            | "kusd" if kusd_balance === None => {
                Js.Promise.resolve()
            }
            | "uusd" if uusd_balance === None => {
                Js.Promise.resolve(())
            }
            | _ => Js.Promise.reject(Js.Exn.raiseError("unknown token " ++ token))
        }
    }
    
    <div className="send-tokens">
        <label>
            <span>{"Token name:"->React.string}</span>
            <select
                defaultValue="none" 
                onChange={event => fetch_token_balance((event->ReactEvent.Form.target)["value"])->ignore}
            >
                <option value="none" disabled=true>{"Select a token"->React.string}</option>
                <option value="ctez">
                    {"Ctez "->React.string}
                    {
                        switch ctez_balance {
                            | None => ""->React.string
                            | Some(balance) => (
                                "(" ++ 
                                (
                                    balance / Js.Math.pow_float(~base=10.0, ~exp=Utils.ctez_address.decimals->Belt.Int.toFloat)->Belt.Float.toInt
                                )
                                ->Belt.Int.toString ++ 
                                ")"
                            )->React.string
                        }
                    }
                </option>
                <option value="kusd">{"kUSD"->React.string}</option>
                <option value="uusd">{"uUSD"->React.string}</option>
            </select>
        </label>
        <label>
            <span>{"Amount:"->React.string}</span>
            <input 
                type_="number"
                // className={if balance_error { "error" } else { "" } }
                // value={
                //     switch amount {
                //         | None => ""
                //         | Some(amt) => amt->Belt.Float.toString
                //     }
                // } 
                // onInput={
                //     event => {
                //         set_balance_error(_ => false)
                //         let (amt, has_error) = Utils.update_amount((event->ReactEvent.Form.target)["value"], user_xtz_balance)
                //         set_amount(_ => amt)
                //         set_balance_error(_ => has_error)
                //     }
                // }
            />
        </label>
        <label>
            <span>{"Recipient:"->React.string}</span>
            <input
                type_="text"
                value={
                    switch recipient {
                        | None => ""
                        | Some(r) => r
                    }
                } 
                onInput={event => set_recipient(_ => (event->ReactEvent.Form.target)["value"]->Some)} 
            />
        </label>
        <button 
            // onClick={_ => transfer()->ignore}
            disabled={transaction_status !== #unknown}
        >
            {
                switch transaction_status {
                    | #pending => "Sending..."
                    | #applied => "Transferred!"
                    | #skipped => "Skipped"
                    | #failed => "Failed!"
                    | #backtracked => "Backtracked"
                    | _ => "Send"
                }
                ->React.string
            }
        </button>
    </div>
}