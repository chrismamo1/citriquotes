open Lwt
open Opium.Std

module List = struct
  include List

  let get_first ls n =
    let rec aux n = function
      | [] -> []
      | hd :: _ when n = 0 -> [hd]
      | hd :: tl ->
          hd :: aux (n - 1) tl
    in
    aux n ls

  let rec to_string = function
    | [] -> ""
    | hd :: tl -> hd ^ "\n" ^ to_string tl
end

let quotes_db = Hashtbl.create 16

let load_index datadir =
  let index_name = Filename.concat datadir "index.txt" in
  Lwt_io.(open_file ~mode:Input index_name)
  >>= fun is ->
  let rec aux acc =
    Lwt_io.read_line_opt is
    >>= fun name ->
    match name with
      | Some name ->
          let name = String.trim name in
          let acc = name :: acc in
          aux acc
      | None ->
          Lwt_io.close is
          >>= fun () ->
          Lwt.return acc
  in
  aux []

let load_quotes datadir name =
  let fname = Filename.concat datadir name in
  Lwt_io.(open_file ~mode:Input fname)
  >>= fun is ->
  let rec aux () =
    Lwt_io.read_line_opt is
    >>= fun quote ->
    match quote with
      | None -> Lwt.return []
      | Some quote -> begin
          Lwt_io.printf "found a quote \"%s\"\n" quote
          >>= fun () ->
          match String.trim quote with
            | "" -> aux ()
            | quote ->
                aux ()
                >>| fun acc ->
                quote :: acc
        end
  in
  aux ()
  >>= fun quotes ->
  let () = Hashtbl.replace quotes_db name quotes in
  Lwt.return quotes

let load_all_quotes datadir =
  load_index datadir
  >>= fun index ->
  Lwt_io.printf "Index: \n\"%s\"\n" (List.to_string index)
  >>= fun () ->
  let rec aux = function
    | name :: names ->
        load_quotes datadir name
        >>= fun _ ->
        (aux[@tailcall]) names
    | [] ->
        Lwt.return ()
  in
  aux index

let get_quote = get "/quotes/:name" (fun req ->
  let name = param req "name" |> String.trim in
  Lwt_io.printf "Trying to get quotes from %s\n" name
  >>= fun () ->
  let quotes =
    try
      Hashtbl.find quotes_db name
    with
      | Not_found ->
          []
  in
  let quotes =
    [%to_yojson: string list] quotes
    |> Yojson.Safe.to_string
  in
  `String (quotes)
  |> respond')

let _ =
  ignore(load_all_quotes "./data/");
  App.empty
  |> get_quote
  |> App.run_command
