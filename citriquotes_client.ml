type quotes_request =
  { count : int option
  ; person : string [@default "Cyrus Roshan"] [@path]
  }
[@@deriving netblob { url = "https://rwkdoivhpo.localtunnel.me/quotes" ; meth = `Get }]
