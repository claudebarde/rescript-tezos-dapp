@react.component
let make = (
        ~tezos: option<Taquito.t>, 
        ~user_address: option<Tezos.account_address>,
        ~user_xtz_balance: option<int>,
        ~disconnect_wallet: () => promise<unit>
    ) => {
    <header style={ReactDOM.Style.make(~display="flex", ~justifyContent="space-between", ~alignItems="center", ~padding="0px 50px", ())}>
        <div>
            {
                switch tezos {
                    | None => "Not connected"
                    | Some(_) => "Connected to Ghostnet"
                }
                ->React.string
            }
        </div>
        <div className="header__right-field">
            {
                switch (user_address, user_xtz_balance) {
                    | (Some(_), Some(balance)) => 
                        <>
                            <div>{("Balance: " ++ (balance / 1_000_000)->Belt.Int.toString ++ " XTZ")->React.string}</div>
                            <button 
                                className="disconnect"
                                onClick={_ => disconnect_wallet()->ignore}
                            >
                                {"Disconnect"->React.string}
                            </button>
                        </>
                    | _ => React.null
                }
            }
        </div>
    </header>
}