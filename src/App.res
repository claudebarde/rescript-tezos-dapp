@react.component
let make = () => {
  let (tezos, set_tezos) = React.useState(() => None)
  let (wallet, set_wallet) = React.useState(() => None)
  let (user_address, set_user_address) = React.useState(() => None)
  let (user_xtz_balance, set_user_xtz_balance) = React.useState(() => None)

  let rpc_url = "https://ghostnet.ecadinfra.com"

  let connect_wallet = async () => {
    switch tezos {
    | None => Js.log("The TezosToolkit hasn't been initialized")
    | Some(tezos) => {
        let beacon_wallet =
          switch wallet {
          | None => {
            // sets the wallet
            let wallet = Beacon_wallet.new_wallet({ name: "ReScript Tezos dapp", preferred_network: "ghostnet" })
            // sets the wallet provider
            tezos->Taquito.set_wallet_provider(wallet)
            set_wallet(_ => wallet->Some)

            wallet
          }
          | Some(w) => w
        }

        // requests permissions
        let _ = await beacon_wallet->Beacon_wallet.request_permissions({ network: { type_: "ghostnet", rpc_url: rpc_url } })
        // gets user's address
        let user_address = await beacon_wallet->Beacon_wallet.get_pkh
        // gets user's XTZ balance
        let user_xtz_balance = (await tezos->Taquito.tz->Taquito.Tz.get_balance(user_address))->Big_number.to_int

        set_user_address(_ => user_address->Some)
        set_user_xtz_balance(_ => user_xtz_balance->Some)
      }
    }
  }

  let disconnect_wallet = async () => {
    switch wallet {
      | None => Js.log("Wallet hasn't been initialized")
      | Some(w) => {
        let _ = await w->Beacon_wallet.client->Beacon_wallet.clear_active_account
        set_wallet(_ => None)
        set_user_address(_ => None)
      }
    }
  }

  let _ = React.useEffect0(() => {
    let init = async () => {
      // sets the TezosToolkit
      let tezos = rpc_url->Taquito.tezos_toolkit
      // sets the wallet
      let wallet = Beacon_wallet.new_wallet({ name: "ReScript Tezos dapp", preferred_network: "ghostnet" })
      // sets the wallet provider
      tezos->Taquito.set_wallet_provider(wallet)
      // checks if there is an active wallet session
      let (user_address, user_xtz_balance) = 
        switch (await wallet->Beacon_wallet.client->Beacon_wallet.get_active_account)->Js.Nullable.toOption {
          | None => (None, None)
          | Some(account_info) => {
            let { address } = account_info
            // gets user's XTZ balance
            let user_balance = (await tezos->Taquito.tz->Taquito.Tz.get_balance(address))->Big_number.to_int

            (Some(address), Some(user_balance))
          }
        }
      
      set_tezos(_ => tezos->Some)
      set_wallet(_ => wallet->Some)
      set_user_address(_ => user_address)
      set_user_xtz_balance(_ => user_xtz_balance)
    }

    let _ = init()

    None
  })

  <>
    <Header tezos user_address user_xtz_balance disconnect_wallet />
    <Body tezos connect_wallet user_address user_xtz_balance />
    <Footer />
  </>
}