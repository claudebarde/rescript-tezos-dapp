open Types

type t = beacon_wallet

type wallet_options = {
    name: string,
    @as("preferredNetwork") preferred_network: string
}

type network_permission = {
    @as("type") type_: string,
    @as("rpcUrl") rpc_url: string
}

type permissions = {
    network: network_permission
}

type dapp_client

type account_info = {
//   accountIdentifier: AccountIdentifier
@as("senderId") sender_id: string,
//   origin: {
//     type: Origin
//     id: string
//   }
@as("publicKey") public_key: string,
address: Tezos.account_address,
@as("connectedAt") connected_at: float,
//   notification?: Notification
}

@new @module("@taquito/beacon-wallet") external new_wallet: wallet_options => t = "BeaconWallet"
@send external request_permissions: (t, permissions) => promise<unit> = "requestPermissions"
@send external get_pkh: t => promise<Tezos.account_address> = "getPKH"
@get external client: t => dapp_client = "client"
@send external get_active_account: dapp_client => promise<Js.Nullable.t<account_info>> = "getActiveAccount"
@send external clear_active_account: dapp_client => promise<unit> = "clearActiveAccount"