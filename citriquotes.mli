type person =
  { name : string
  ; quotes : string list
  }
[@@deriving yojson]
