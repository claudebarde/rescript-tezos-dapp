@react.component
let make = (
        ~tezos: option<Taquito.t>,
        ~connect_wallet: () => promise<unit>,
        ~user_address: option<string>,
        ~user_xtz_balance: option<int>,
        ~set_user_xtz_balance: (option<int> => option<int>) => unit
    ) => {
    let (active_tab, set_active_tab) = React.useState(() => "tokens")

    <main>
        <div className="container">
            <div>
                <h1>{"Tezos ReScript dapp"->React.string}</h1>
                <h3>{"Transfer tokens to another account"->React.string}</h3>
            </div>
            {
                switch (tezos, user_address) {
                    | (None, _) => React.null
                    | (Some(_), None) => 
                        <button 
                            className="wallet-button"
                            onClick={_ => connect_wallet()->ignore}
                        >
                            {"Connect wallet"->React.string}
                        </button>
                    | (Some(_), Some(_)) => 
                        <>
                            <div className="tabs-container">
                                <div className="tabs">
                                    <button 
                                        className={if active_tab === "xtz" { "active" } else { "" }}
                                        onClick={_ => set_active_tab(_ => "xtz")}
                                    >
                                        {"Send XTZ"->React.string}
                                    </button>
                                    <button 
                                        className={if active_tab === "tokens" { "active" } else { "" }}
                                        onClick={_ => set_active_tab(_ => "tokens")}
                                    >
                                        {"Send tokens"->React.string}
                                    </button>
                                </div>
                                <div className="tab-selection">
                                    {
                                        if active_tab === "xtz" {
                                            <Send_xtz user_xtz_balance tezos set_user_xtz_balance />
                                        } else if active_tab === "tokens" {
                                            <Send_tokens tezos user_address />
                                        } else {
                                            React.null
                                        }
                                    }
                                </div>
                            </div>
                            <a 
                                href="https://faucet.marigold.dev/"
                                target="_blank"
                                rel="noreferrer noopener nofollow"
                            >
                                {"Click here to get testnet tokens"->React.string} 
                            </a>
                        </>
                }
            }
        </div>
    </main>
}