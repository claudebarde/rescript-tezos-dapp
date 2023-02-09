type account_address = string

module Transaction_status = {
    type t  = Pending | Applied | Failed | Skipped | Backtracked | Unknown
}