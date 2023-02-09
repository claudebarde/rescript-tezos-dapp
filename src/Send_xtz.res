@react.component
let make = (
        ~user_xtz_balance: option<int>,
        ~tezos: option<Taquito.t>
    ) => {
    let (amount, set_amount) = React.useState(() => None)
    let (recipient, set_recipient) = React.useState(() => None)
    let (balance_error, set_balance_error) = React.useState(() => false)
    let (transaction_status, set_transaction_status) = React.useState(() => Tezos.Transaction_status.Unknown)

    let update_amount = (amt: string) => {
        let _ = set_balance_error(_ => false)
        switch amt->Belt.Float.fromString {
            | None => set_amount(_ => None)
            | Some(amount) => {
                if amount === 0.0 {
                    set_amount(_ => None)
                } else {
                    switch user_xtz_balance {
                        | None => set_amount(_ => None)
                        | Some(balance) => 
                            // displays error
                            if balance->Belt.Int.toFloat < amount *. 1_000_000.0 {
                                let _ = set_balance_error(_ => true)
                            }
                            set_amount(_ => (Some(amount)))
                    }
                }
            }
        }
    }

    let transfer = async () => {
        open Taquito 

        set_transaction_status(_ => Tezos.Transaction_status.Pending)
        switch (tezos, amount, recipient) {
            | (Some(tezos), Some(amount), Some(recipient)) => {
                switch await (await tezos->wallet->Wallet.transfer({ to: recipient, amount }))->Wallet.send {
                    | op => {
                        let _ = await op->Operation.confirmation
                        let status = await op->Operation.status
                        if status === "applied" {
                            set_transaction_status(_ => Tezos.Transaction_status.Applied)
                            set_amount(_ => None)
                            set_recipient(_ => None)
                        } else if status === "skipped" {
                            set_transaction_status(_ => Tezos.Transaction_status.Skipped)
                        } else if status === "failed" {
                            set_transaction_status(_ => Tezos.Transaction_status.Failed)
                        } else if status === "backtracked" {
                            set_transaction_status(_ => Tezos.Transaction_status.Backtracked)
                        } else {
                            set_transaction_status(_ => Tezos.Transaction_status.Unknown)
                        }

                        let _ = Js.Global.setTimeout(() => set_transaction_status(_ => Tezos.Transaction_status.Unknown), 2_000)

                        ()
                    }
                    | exception JsError(err) => err->Js.log
                }

                ()
            }
            | _ => Js.log("Missing TezosToolkit, amount or recipient for transfer")
        }
    }    

    <div className="send-tokens">
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
                onInput={event => update_amount((event->ReactEvent.Form.target)["value"])} 
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
            disabled={transaction_status !== Tezos.Transaction_status.Unknown}
        >
            {
                switch transaction_status {
                    | Pending => "Sending..."
                    | Applied => "Transferred!"
                    | Skipped => "Skipped"
                    | Failed => "Failed!"
                    | Backtracked => "Backtracked"
                    | _ => "Send"
                }
                ->React.string
            }
        </button>
    </div>
}