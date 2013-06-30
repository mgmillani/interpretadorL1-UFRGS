open Semantics;;
open TypeSystem;;
open Syntax;;


(* Converte tipo para string *)
let rec tipo_to_string (tp:tipo) : string =
  match tp with
  | Tbool -> "bool"
  | Tint  -> "int"
  | Tfun(tp1,tp2) -> "(" ^ (tipo_to_string tp1) ^ " -> " ^ (tipo_to_string tp2) ^ ")"
;;

(* Converte termo para string *)
let rec term_to_string (t:term) : string =
  match t with
  | Num(x) -> string_of_int x
  | Bool(true) -> "true"
  | Bool(false) -> "false"
  | Binop(Plus,t1,t2) -> "(" ^ (term_to_string t1) ^ " + " ^ (term_to_string t2) ^ ")"
  | Binop(Geq,t1,t2) -> "(" ^ (term_to_string t1) ^ " >= " ^ (term_to_string t2) ^ ")"
  | If(t1,t2,t3) -> "(if " ^ (term_to_string t1) ^ " then " ^ (term_to_string t2) ^ " else " ^ (term_to_string t3) ^ ")"
  | Var(x) -> x
  | App(t1,t2) -> "(" ^ (term_to_string t1) ^ " " ^ (term_to_string t2) ^ ")"
  | Fun(x,tp,t1) -> "(fun " ^ x ^ ":" ^ (tipo_to_string tp) ^ "=>" ^ (term_to_string t1) ^ ")"
  | Let(x,tp,t1,t2) -> "(let " ^ x ^ ":" ^ (tipo_to_string tp) ^ "=" ^ (term_to_string t1) ^ " in " ^ (term_to_string t2) ^ ")"
  | LetRec(x,tp,t1,t2) -> "(let rec " ^ x ^ ":" ^ (tipo_to_string tp) ^ "=" ^ (term_to_string t1) ^ " in " ^ (term_to_string t2) ^ ")"
;;

(*  TESTES *)

let test1 = (Fun ("x",Tint,Binop(Plus,Binop(Plus, Var "x", Num 1),Num 2))) ;;
let test2 = Num(23) ;;
let test3 = App(test1,test2) ;;

let test4 = Let("x",Tint,Num(6),Binop(Plus,Var "x",Num 3));;
let test5 = Let("y",Tint,Fun("y",Tint,Binop(Geq,Var "y",Num 5)),App(Var "y",Num 2));;
let test6 = LetRec("sum",Tfun (Tint,Tint),Fun("y",Tint,If(Binop(Geq, Var "y" , Num 0), Binop(Plus,Var "y", Num 1), Num 0 )),App(Var "sum",Num 5));;

let rec testAll lst = match lst with
	| (h::r) ->
		print_endline (term_to_string h);
		print_endline (term_to_string (eval h));
		let t = typeCheck h (Hashtbl.create 88) in
		(match t with
			| Some t0 -> print_endline (tipo_to_string t0)
			| None -> print_endline "Ill-typed")
		;
		print_endline "###########";
		testAll r
	| [] -> ();;

let tests = [test1;test2;test3;test4;test5;test6];;

testAll tests;

(*let typeTest1 = typeCheck (Num 88) (Hashtbl.create 88);;*)

