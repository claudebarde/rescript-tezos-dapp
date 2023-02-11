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
        switch (tezos, user_address, token) {
        | (Some(tezos), Some(address), "ctez" | "kusd" | "uusd") => {
            if token === "ctez" && ctez_balance === None {
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.ctez_contract.address))->storage {
                        | (storage: Tezos.fa1_2_storage) => {
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
                        | exception JsError(_) => {
                            Js.log("Unable to fetch the storage of the Ctez contract")

                            None
                        }
                    }
                }
                set_ctez_balance(_ => balance)
            } else if token === "kusd" && kusd_balance === None {
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.kusd_contract.address))->storage {
                        | (storage: Tezos.fa1_2_storage) => {
                        switch await storage.tokens->Big_map.get(address) {
                            | (balance: Js.Nullable.t<Big_number.big_int>) => {
                                switch balance->Js.Nullable.toOption {
                                    | None => None
                                    | Some(blnc) => blnc->Big_number.to_int->Some
                                }
                            }
                            | exception JsError(_) => {
                                let _ = Js.log("Unable to fetch the user's kUSD balance")

                                None
                            }
                        }
                        }
                        | exception JsError(_) => {
                            Js.log("Unable to fetch the storage of the kUSD contract")

                            None
                        }
                    }
                }
                set_kusd_balance(_ => balance)
            } else if token === "uusd" && uusd_balance === None {
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.uusd_contract.address))->storage {
                        | (storage: Tezos.fa2_storage) => {
                        let key = { "0": address, "1": Utils.uusd_contract.token_id }
                        switch await storage.ledger->Big_map.get(key) {
                            | (balance: Js.Nullable.t<Big_number.big_int>) => {
                                switch balance->Js.Nullable.toOption {
                                    | None => None
                                    | Some(blnc) => blnc->Big_number.to_int->Some
                                }
                            }
                            | exception JsError(_) => {
                                let _ = Js.log("Unable to fetch the user's uUSD balance")

                                None
                            }
                        }
                        }
                        | exception JsError(_) => {
                            Js.log("Unable to fetch the storage of the uUSD contract")

                            None
                        }
                    }
                }
                set_uusd_balance(_ => balance)
            }
            
            Js.Promise.resolve(())
        }
        | (Some(_), _, _) => Js.Promise.reject(Js.Exn.raiseError("Unknown token " ++ token))
        | (_, None, _) => Js.Promise.reject(Js.Exn.raiseError("User address is unknown"))
        | (None, _, _) => Js.Promise.reject(Js.Exn.raiseError("TezosToolkit hasn't been initialized"))
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
                            | Some(balance) => ("(" ++ Utils.display_amount(balance, "ctez") ++ ")")->React.string
                        }
                    }
                </option>
                <option value="kusd">
                    {"kUSD "->React.string}
                    {
                        switch kusd_balance {
                            | None => ""->React.string
                            | Some(balance) => ("(" ++ Utils.display_amount(balance, "kusd") ++ ")")->React.string
                        }
                    }
                </option>
                <option value="uusd">
                    {"uUSD "->React.string}
                    {
                        switch uusd_balance {
                            | None => ""->React.string
                            | Some(balance) => ("(" ++ Utils.display_amount(balance, "uusd") ++ ")")->React.string
                        }
                    }
                </option>
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