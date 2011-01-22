let mod_dir = Sys.argv.(1) ;;
let base_lang = Sys.argv.(2) ;;
let langs = Array.to_list (Array.sub Sys.argv 2 (Array.length Sys.argv - 2)) ;;
let tra_dir = mod_dir ^ "/tra/";;
let temp_dir = "tb#traifier_tmp_dir" ;;

let log_and_print fmt = 
  let k result = output_string stdout result ; flush stdout in
  Printf.kprintf k fmt
;;

let mkdir directory =
  let dir_split = Str.split (Str.regexp "[/\\]") directory in
  let added_up_dir = ref "" in
  let skip_first_slash = ref false in
  if String.get directory 0 = '\\' || String.get directory 0 = '/' then skip_first_slash := true ;
  List.iter ( fun part ->
    added_up_dir := !added_up_dir ^ (if !skip_first_slash then "/" else "") ^ part ;
    skip_first_slash := true ;
    try
      Unix.mkdir !added_up_dir 0o755;
    with e -> (
      match e with
      | Unix.Unix_error(Unix.EEXIST,_,_) -> ()
      | _ -> log_and_print "Problem %s on %s: util.ml\n" (Printexc.to_string e) !added_up_dir ;
     )
	) dir_split
;;

let file_size name =
  try 
    let stats = Unix.stat name in
    stats.Unix.st_size 
  with _ ->  -1
;;

let file_exists name =
  file_size name >= 0
;;

let is_directory name =
  try
    let stats = Unix.stat name in
    let res = stats.Unix.st_kind = Unix.S_DIR in
    res 
  with _ -> false
;;

let my_read size fd buff name = 
  let sofar = ref 0 in
  while !sofar < size do 
    let this_chunk = Unix.read fd buff !sofar (size - !sofar) in
    if this_chunk = 0 then begin
      failwith (Printf.sprintf "read %d of %d bytes from [%s]"
		  !sofar size name) 
    end else 
      sofar := !sofar + this_chunk
  done 
;;

let load_file name =
	let stats = Unix.stat name in
	let size = stats.Unix.st_size in
	let buff = String.make size '\000' in
	let fd = Unix.openfile name [Unix.O_RDONLY] 0 in
	my_read size fd buff name ;
	Unix.close fd ;
	buff
;;

let command cmd =
  log_and_print "\n%s\n\n" cmd;
  ignore (Sys.command cmd);
;;

let rename oldname newname =
  if file_exists newname then Sys.remove newname;
  Sys.rename oldname newname
;;

let is_traificable path =
  let path = String.lowercase path in
  (Filename.check_suffix path ".d" || Filename.check_suffix path ".baf" ||
  Filename.check_suffix path ".tp2" || Filename.check_suffix path ".tph" ||
  Filename.check_suffix path ".tpa" || Filename.check_suffix path ".tpp")
;;

let rec find where validity =
  let files = Array.to_list (Sys.readdir where) in
  List.flatten (List.map (fun file ->
    let path = where ^ "/" ^ file in
    if is_directory path then begin
      if String.lowercase file = "tra" then
        []
      else
        find path validity
    end else begin
      if validity path then 
        [ path ]
      else 
        []
    end
  ) files)
;;

let traify path tmpfile finaltra =
  if file_size finaltra > 0 then
    command (Printf.sprintf "weidu --traify %s --out %s --traify-old-tra %s"
                                            path     tmpfile             finaltra)
  else
    command (Printf.sprintf "weidu --traify %s --out %s"
                                            path     tmpfile)
;;

let detraify filename path trabase =
  let has_tra = try 
      let file = load_file path in
      ignore (String.index file '@');
      true
    with _ -> false
  in
  if has_tra then List.iter (fun lang ->
    let finaltra = tra_dir ^ lang ^ "/" ^ trabase in
    let finalfile = tra_dir ^ lang ^ "/decompiled/" ^ filename in
    if file_size finaltra > 0 then
      command (Printf.sprintf "weidu --untraify-d %s --untraify-tra %s --out %s"
                                                   path              finaltra finalfile
      )
  ) langs
;;

let main () =
  mkdir temp_dir;
  List.iter (fun lang -> mkdir (Printf.sprintf "%s/tra/%s/decompiled" mod_dir lang)) langs;
  let to_tra = List.sort compare (find mod_dir is_traificable) in
  List.iter (fun path ->
    let filename = Filename.basename path in
    let tmpfile = temp_dir ^ "/" ^ filename in
    let tmptra = Filename.chop_extension tmpfile ^ ".tra" in
    let trabase = 
      let filename = String.lowercase filename in
      if Filename.check_suffix filename ".d" then
        Filename.chop_suffix filename ".d" ^ ".tra"
      else
        "/setup.tra"
    in
    let finaltra = tra_dir ^ base_lang ^ "/" ^ trabase in
    traify path tmpfile finaltra;
    rename tmpfile path;
    if file_size tmptra > 0 then begin
      rename tmptra finaltra;
      detraify filename path trabase;
    end else Sys.remove tmptra;
  ) to_tra;
  Unix.rmdir temp_dir;
;;

main ();
