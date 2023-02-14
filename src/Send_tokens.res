type action = 
| Amount(option<float>)
| Recipient(option<Tezos.account_address>)
| Balance_error(bool)
| Transaction_status(Taquito.Operation.status)
| Selected_token(option<string>)
| Ctez_balance(option<float>)
| Kusd_balance(option<float>)
| Uusd_balance(option<float>)

type state = {
    amount: option<float>,
    recipient: option<Tezos.account_address>,
    balance_error: bool,
    transaction_status: Taquito.Operation.status,
    selected_token: option<string>,
    ctez_balance: option<float>,
    kusd_balance: option<float>,
    uusd_balance: option<float>
}

let reducer = (state, action) => {
    switch action {
    | Amount(amount) => { ...state, amount }
    | Recipient(recipient) => { ...state, recipient }
    | Balance_error(err) => { ...state, balance_error: err }
    | Transaction_status(status) => { ...state, transaction_status: status }
    | Selected_token(selected_token) => { ...state, selected_token }
    | Ctez_balance(ctez_balance) => { ...state, ctez_balance }
    | Kusd_balance(kusd_balance) => { ...state, kusd_balance }
    | Uusd_balance(uusd_balance) => { ...state, uusd_balance }
    }
}

@react.component
let make = (
        ~tezos: option<Taquito.t>,
        ~user_address: option<string>,
    ) => {
    // let (amount, set_amount) = React.useState(() => None)
    // let (recipient, set_recipient) = React.useState(() => None)
    // let (balance_error, set_balance_error) = React.useState(() => false)
    // let (transaction_status, set_transaction_status) = React.useState(() => #unknown)
    // let (selected_token, set_selected_token) = React.useState(() => None)
    // let (ctez_balance, set_ctez_balance) = React.useState(() => None)
    // let (kusd_balance, set_kusd_balance) = React.useState(() => None)
    // let (uusd_balance, set_uusd_balance) = React.useState(() => None)
    let initial_state: state = {
        amount: None,
        recipient: None,
        balance_error: false,
        transaction_status: #unknown,
        selected_token: None,
        ctez_balance: None,
        kusd_balance: None,
        uusd_balance: None
    }
    let (state, dispatch) = React.useReducer(reducer, initial_state)

    let fetch_token_balance = async (token: string): promise<unit> => {
        switch (tezos, user_address, token) {
        | (Some(tezos), Some(address), "ctez" | "kusd" | "uusd") => {
            if token === "ctez" && state.ctez_balance === None {
                let _ = dispatch(Selected_token(Some(token)))
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
                dispatch(Ctez_balance(balance))
            } else if token === "kusd" && state.kusd_balance === None {
                let _ = dispatch(Selected_token(Some(token)))
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
                dispatch(Kusd_balance(balance))
            } else if token === "uusd" && state.uusd_balance === None {
                let _ = dispatch(Selected_token(Some(token)))
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
                dispatch(Uusd_balance(balance))
            }
            
            Js.Promise.resolve(())
        }
        | (Some(_), _, _) => Js.Promise.reject(Js.Exn.raiseError("Unknown token " ++ token))
        | (_, None, _) => Js.Promise.reject(Js.Exn.raiseError("User address is unknown"))
        | (None, _, _) => Js.Promise.reject(Js.Exn.raiseError("TezosToolkit hasn't been initialized"))
        }
    }

    let transfer = async () => {
        switch state.selected_token {
        | None => Js.Promise.reject(Js.Exn.raiseError("No token is selected"))
        | Some(token) => {
            open Taquito
            open Wallet
            open ContractAbstraction

            #pending->Transaction_status->dispatch

            switch (tezos, state.amount, user_address, state.recipient) {
                | (Some(tezos), Some(amt), Some(address), Some(recipient)) => {
                    let balance =
                        switch token {
                            | "ctez" => {
                                switch state.ctez_balance {
                                | None => Error("No Ctez balance available")
                                | Some(blnc) => Ok(blnc)
                                }
                            }
                            | "kusd" => {
                                switch state.kusd_balance {
                                | None => Error("No kUSD balance available")
                                | Some(blnc) => Ok(blnc)
                                }
                            }
                            | "uusd" => {
                                switch state.uusd_balance {
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
                                                #applied->Transaction_status->dispatch
                                                dispatch(Amount(None))
                                                dispatch(Recipient(None))
                                                let _ = switch token {
                                                    | "ctez" => {
                                                        switch state.ctez_balance {
                                                            | None => None
                                                            | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                        }
                                                        ->Ctez_balance
                                                        ->dispatch
                                                    }
                                                    | "kusd" => {
                                                        switch state.kusd_balance {
                                                            | None => None
                                                            | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                        }
                                                        ->Kusd_balance
                                                        ->dispatch
                                                    }
                                                    | "uusd" => {
                                                        switch state.uusd_balance {
                                                            | None => None
                                                            | Some(prev_balance) => (prev_balance -. amount_)->Some
                                                        }
                                                        ->Uusd_balance
                                                        ->dispatch
                                                    }
                                                    | _ => ()
                                                }

                                                let _ = Js.Global.setTimeout(() => #unknown->Transaction_status->dispatch, 2_000)

                                                Js.Promise.resolve(())
                                            }
                                            | status => {
                                                status->Transaction_status->dispatch
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
                        switch state.ctez_balance {
                            | None => ""->React.string
                            | Some(balance) => ("(" ++ Utils.display_amount(balance, "ctez") ++ ")")->React.string
                        }
                    }
                </option>
                <option value="kusd">
                    {"kUSD "->React.string}
                    {
                        switch state.kusd_balance {
                            | None => ""->React.string
                            | Some(balance) => ("(" ++ Utils.display_amount(balance, "kusd") ++ ")")->React.string
                        }
                    }
                </option>
                <option value="uusd">
                    {"uUSD "->React.string}
                    {
                        switch state.uusd_balance {
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
                className={if state.balance_error { "error" } else { "" } }
                value={
                    switch state.amount {
                        | None => ""
                        | Some(amt) => amt->Belt.Float.toString
                    }
                } 
                onInput={
                    event => {
                        dispatch(Balance_error(false))
                        let (amt, has_error) = {
                            let balance = {
                                switch state.selected_token {
                                | None => None
                                | Some(token) =>
                                    if token === "ctez" {
                                        state.ctez_balance
                                    } else if token === "kusd" {
                                        state.kusd_balance
                                    } else if token === "uusd" {
                                         state.uusd_balance
                                    } else {
                                        None
                                    }
                                }
                            }
                            Utils.update_amount((event->ReactEvent.Form.target)["value"], balance)
                        }
                        amt->Amount->dispatch
                        dispatch(Balance_error(has_error))
                    }
                }
            />
        </label>
        <label>
            <span>{"Recipient:"->React.string}</span>
            <input
                type_="text"
                value={
                    switch state.recipient {
                        | None => ""
                        | Some(r) => r
                    }
                } 
                onInput={event => (event->ReactEvent.Form.target)["value"]->Some->Recipient->dispatch} 
            />
        </label>
        <button 
            onClick={_ => transfer()->ignore}
            disabled={state.transaction_status !== #unknown}
        >
            {
                switch state.transaction_status {
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