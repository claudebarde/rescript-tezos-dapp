@react.component
let make = () => {
    let (amount, set_amount) = React.useState(() => None)
    let (recipient, set_recipient) = React.useState(() => None)
    let (transaction_status, set_transaction_status) = React.useState(() => #unknown)

    let fetch_token_balance = async (token: string) => {
        token->Js.log
    }
    
    <div className="send-tokens">
        <label>
            <span>{"Token name:"->React.string}</span>
            <select
                defaultValue="none" 
                onChange={event => fetch_token_balance((event->ReactEvent.Form.target)["value"])->ignore}
            >
                <option value="none" disabled=true>{"Select a token"->React.string}</option>
                <option value="ctez">{"Ctez"->React.string}</option>
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