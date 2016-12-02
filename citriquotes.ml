open Lwt
open Opium.Std

type person =
  { name : string
  ; quotes : string list
  }
[@@deriving yojson]

module List = struct
  include List

  let get_first ls n =
    let rec aux n = function
      | [] -> []
      | hd :: _ when n = 0 -> []
      | hd :: tl ->
          hd :: aux (n - 1) tl
    in
    aux n ls
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
  let count =
    Uri.get_query_param
      (req.request
        |> Cohttp_lwt.Request.uri)
      "count"
    |> function
        | Some x -> Some (int_of_string x)
        | None -> None
  in
  let quotes =
    Hashtbl.fold
      (fun k v acc ->
        if k = name || name = "*"
        then
          let v =
            match count with
              | Some count -> List.get_first v count
              | None -> v
          in
          Yojson.Safe.(k, [%to_yojson: string list] v) :: acc
        else
          acc)
      quotes_db
      []
    |> fun x -> `Assoc x
  in
  `String (Yojson.Safe.to_string quotes)
  |> respond')

let _ =
  ignore(load_all_quotes "./data/");
  App.empty
  |> get_quote
  |> App.run_command
