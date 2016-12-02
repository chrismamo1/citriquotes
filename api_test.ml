open Lwt

let main () =
  let%lwt resp =
    Citriquotes_client.netblob_quotes_request ~count:1 ~person:"Cyrus Roshan" ()
  in
  let json = Yojson.Safe.from_string resp in
  Lwt.return (Yojson.Safe.to_string json)

let () =
  Lwt_main.run main
