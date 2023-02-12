@react.component
let make = (
        ~tezos: option<Taquito.t>,
        ~user_address: option<string>,
    ) => {
    let (amount, set_amount) = React.useState(() => None)
    let (recipient, set_recipient) = React.useState(() => None)
    let (balance_error, set_balance_error) = React.useState(() => false)
    let (transaction_status, set_transaction_status) = React.useState(() => #unknown)
    let (selected_token, set_selected_token) = React.useState(() => None)
    let (ctez_balance, set_ctez_balance) = React.useState(() => None)
    let (kusd_balance, set_kusd_balance) = React.useState(() => None)
    let (uusd_balance, set_uusd_balance) = React.useState(() => None)

    let fetch_token_balance = async (token: string): promise<unit> => {
        switch (tezos, user_address, token) {
        | (Some(tezos), Some(address), "ctez" | "kusd" | "uusd") => {
            if token === "ctez" && ctez_balance === None {
                let _ = set_selected_token(_ => Some(token))
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.ctez_contract.address))->storage {
                        | (storage: Tezos.fa1_2_storage) => {
                            switch await storage.tokens->Big_map.get(address) {
                                | (balance: Js.Nullable.t<Big_number.big_float>) => {
                                    switch balance->Js.Nullable.toOption {
                                        | None => None
                                        | Some(blnc) => blnc->Big_number.to_float->Some
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
                let _ = set_selected_token(_ => Some(token))
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.kusd_contract.address))->storage {
                        | (storage: Tezos.fa1_2_storage) => {
                        switch await storage.tokens->Big_map.get(address) {
                            | (balance: Js.Nullable.t<Big_number.big_float>) => {
                                switch balance->Js.Nullable.toOption {
                                    | None => None
                                    | Some(blnc) => blnc->Big_number.to_float->Some
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
                let _ = set_selected_token(_ => Some(token))
                let balance = {
                    open Taquito
                    open Wallet
                    open ContractAbstraction

                    switch await (await tezos->wallet->at(Utils.uusd_contract.address))->storage {
                        | (storage: Tezos.fa2_storage) => {
                        let key = { "0": address, "1": Utils.uusd_contract.token_id }
                        switch await storage.ledger->Big_map.get(key) {
                            | (balance: Js.Nullable.t<Big_number.big_float>) => {
                                switch balance->Js.Nullable.toOption {
                                    | None => None
                                    | Some(blnc) => blnc->Big_number.to_float->Some
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

    let transfer = async () => {
        switch selected_token {
        | None => Js.Promise.reject(Js.Exn.raiseError("No token is selected"))
        | Some(token) => {
            open Taquito
            open Wallet
            open ContractAbstraction

            set_transaction_status(_ => #pending)

            switch (tezos, amount, user_address, recipient) {
                | (Some(tezos), Some(amt), Some(address), Some(recipient)) => {
                    let balance =
                        switch token {
                            | "ctez" => {
                                switch ctez_balance {
                                | None => Error("No Ctez balance available")
                                | Some(blnc) => Ok(blnc)
                                }
                            }
                            | "kusd" => {
                                switch kusd_balance {
                                | None => Error("No kUSD balance available")
                                | Some(blnc) => Ok(blnc)
                                }
                            }
                            | "uusd" => {
                                switch uusd_balance {
                                | None => Error("No uUSD balance available")
                                | Some(blnc) => Ok(blnc)
                                }
                            }
                            | _ => Error("Unknown token")
                        }

                    switch balance {
                        | Error(err) => Js.Promise.reject(Js.Exn.raiseError(err))
                        | Ok(balance) => {
                            // checks that the amount is less than the user's balance
                            let amount_ = Utils.amount_with_decimals(amt, token)
                            if amount_ <= balance {
                                let contract_call = 
                                    switch token {
                                        | "ctez" => {
                                            let contract = await tezos->wallet->at(Utils.ctez_contract.address)
                                            Ok(contract
                                            ->fa1_2_methods
                                            ->Fa1_2_entrypoints.transfer(~from=address, ~to=recipient, ~value=amount_))
                                        }
                                        | "kusd" => {
                                            let contract = await tezos->wallet->at(Utils.kusd_contract.address)
                                            Ok(contract
                                            ->fa1_2_methods
                                            ->Fa1_2_entrypoints.transfer(~from=address, ~to=recipient, ~value=amount_))
                                        }
                                        | "uusd" => {
                                            let contract = await tezos->wallet->at(Utils.uusd_contract.address)
                                            Ok(contract
                                            ->fa2_methods
                                            ->Fa2_entrypoints.transfer([
                                                { 
                                                    from_: address, 
                                                    tx: [{ 
                                                        to_: recipient, 
                                                        token_id: Utils.uusd_contract.token_id, 
                                                        quantity: amount_ 
                                                    }] 
                                                }
                                            ]))
                                        }
                                        | _ => Error("Unknown token")
                                    }

                                switch contract_call {
                                    | Error(err) => Js.Promise.reject(Js.Exn.raiseError(err))
                                    | Ok(contract_call) => {
                                        let op = await contract_call->Contract_call.send(None)
                                        // waits for confirmation
                                        let _ = await op->Operation.confirmation
                                        // gets the operation status
                                        switch await op->Operation.status {
                                            | #applied => {
                                                set_transaction_status(_ => #applied)
                                                set_amount(_ => None)
                                                set_recipient(_ => None)
                                                let _ = switch token {
                                                    | "ctez" => {
                                                        set_ctez_balance(prev => {
                                                            switch prev {
                                                                | None => None
                                                                | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                            }
                                                        })
                                                    }
                                                    | "kusd" => {
                                                        set_kusd_balance(prev => {
                                                            switch prev {
                                                                | None => None
                                                                | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                            }
                                                        })
                                                    }
                                                    | "uusd" => {
                                                        set_uusd_balance(prev => {
                                                            switch prev {
                                                                | None => None
                                                                | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                            }
                                                        })
                                                    }
                                                    | _ => ()
                                                }

                                                let _ = Js.Global.setTimeout(() => set_transaction_status(_ => #unknown), 2_000)

                                                Js.Promise.resolve(())
                                            }
                                            | status => {
                                                set_transaction_status(_ => status)
                                                Js.Promise.reject(Js.Exn.raiseError("Transaction was not applied, status: " ++ (status :> string)))
                                            }
                                        }  
                                    }
                                }
                            } else {
                                Js.Promise.reject(Js.Exn.raiseError("Amount is greater than user's balance"))
                            }
                        }
                    }

                    /* if token === "ctez" {
                        switch ctez_balance {
                            | None => Js.Promise.reject(Js.Exn.raiseError("No Ctez balance available"))
                            | Some(balance) => {
                                // checks that the amount is less than the user's balance
                                let amount_ = Utils.amount_with_decimals(amt, "ctez")
                                if amount_ <= balance {
                                    // prepares the operation
                                    let contract = await tezos->wallet->at(Utils.ctez_contract.address)
                                    let op = 
                                        await contract
                                        ->ctez_methods
                                        ->Ctez_entrypoints.transfer(~from=address, ~to=recipient, ~value=amount_)
                                        ->Contract_call.send(None)
                                    // waits for confirmation
                                    let _ = await op->Operation.confirmation
                                    // gets the operation status
                                    switch await op->Operation.status {
                                    | #applied => {
                                        set_transaction_status(_ => #applied)
                                        set_amount(_ => None)
                                        set_recipient(_ => None)
                                        set_ctez_balance(prev => {
                                            switch prev {
                                                | None => None
                                                | Some(prev_balance) => (prev_balance - amount_)->Some
                                            }
                                        })

                                        let _ = Js.Global.setTimeout(() => set_transaction_status(_ => #unknown), 2_000)

                                        Js.Promise.resolve(())
                                    }
                                    | status => {
                                        set_transaction_status(_ => status)
                                        Js.Promise.reject(Js.Exn.raiseError("Transaction was not applied, status: " ++ (status :> string)))
                                    }
                                    }                                    
                                } else {
                                    Js.Promise.reject(Js.Exn.raiseError("Amount is greater than user's balance"))
                                }
                            }
                        }
                    } else {
                        Js.Promise.reject(Js.Exn.raiseError("Unhandled token"))
                    } */
                }
                | (None, _, _, _) => Js.Promise.reject(Js.Exn.raiseError("No TezosToolkit available"))
                | (_, None, _, _) => Js.Promise.reject(Js.Exn.raiseError("No amount available"))
                | (_, _, None, _) => Js.Promise.reject(Js.Exn.raiseError("No user address available"))
                | (_, _, _, None) => Js.Promise.reject(Js.Exn.raiseError("No recipient address available"))
            }
        }
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
                className={if balance_error { "error" } else { "" } }
                value={
                    switch amount {
                        | None => ""
                        | Some(amt) => amt->Belt.Float.toString
                    }
                } 
                onInput={
                    event => {
                        set_balance_error(_ => false)
                        let (amt, has_error) = {
                            let balance = {
                                switch selected_token {
                                | None => None
                                | Some(token) =>
                                    if token === "ctez" {
                                        ctez_balance
                                    } else if token === "kusd" {
                                        kusd_balance
                                    } else if token === "uusd" {
                                         uusd_balance
                                    } else {
                                        None
                                    }
                                }
                            }
                            Utils.update_amount((event->ReactEvent.Form.target)["value"], balance)
                        }
                        set_amount(_ => amt)
                        set_balance_error(_ => has_error)
                    }
                }
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
            onClick={_ => transfer()->ignore}
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