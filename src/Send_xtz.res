@react.component
let make = (
        ~user_xtz_balance: option<int>,
        ~tezos: option<Taquito.t>,
        ~set_user_xtz_balance: (option<int> => option<int>) => unit
    ) => {
    let (amount, set_amount) = React.useState(() => None)
    let (recipient, set_recipient) = React.useState(() => None)
    let (balance_error, set_balance_error) = React.useState(() => false)
    let (transaction_status, set_transaction_status) = React.useState(() => #unknown)

    let transfer = async () => {
        open Taquito 

        set_transaction_status(_ => #pending)
        switch (tezos, amount, recipient) {
            | (Some(tezos), Some(amount), Some(recipient)) => {
                switch await (await tezos->wallet->Wallet.transfer({ to: recipient, amount }))->Wallet.send {
                    | op => {
                        let _ = await op->Operation.confirmation
                        switch await op->Operation.status {
                            | #applied => {
                                set_transaction_status(_ => #applied)
                                set_amount(_ => None)
                                set_recipient(_ => None)
                                set_user_xtz_balance(prev => {
                                    switch prev {
                                        | None => None
                                        | Some(prev_balance) => (prev_balance - (amount->Belt.Float.toInt * 1_000_000))->Some
                                    }
                                })
                            }
                            | status => set_transaction_status(_ => status)
                        }

                        let _ = Js.Global.setTimeout(() => set_transaction_status(_ => #unknown), 2_000)

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
                onInput={
                    event => {
                        set_balance_error(_ => false)
                        let (amt, has_error) = Utils.update_amount((event->ReactEvent.Form.target)["value"], user_xtz_balance)
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