open Syntax;;

(* SEMÂNTICA *)


(* função auxiliar: união de conjuntos l1 e l2 (implementados sobre listas) *)
let rec union (l1: 'a list) (l2: 'a list) : 'a list =
  match (l1,l2) with
  | ([],x) -> x
  | (h::t,x) -> if List.mem h x
                  then union t x
                  else union t (h::x)
;;

(* função auxiliar: remove elemento a do conjunto l (implementado sobre lista) *)
let rec remove a l =
  List.filter (fun x -> x <> a) l
;;

(* calcula as variáveis livres de um termo *)
let rec fv (t:term) : string list =
  match t with
  | Num  (_)         -> []
  | Bool (_)         -> []
  | Binop (op,t1,t2) -> union (fv t1) (fv t2)
  | If (t1,t2,t3)    -> union (union (fv t1) (fv t2)) (fv t3)
  | Var (x)          -> [x]
  | App (t1,t2)      -> union (fv t1) (fv t2)
  | Fun (x,tp,t1)    -> remove x (fv t1)
  | Let (x,tp,t1,t2) -> union (fv t1) (remove x (fv t2))
;;

(* função auxiliar: garante um novo nome de variável, certamente distinto de todas as variáveis contidas na lista recebida como parâmetro *)
let rec newVar (l : string list) : string =
  let rec loop n = let t = "z" ^ (string_of_int n)
                   in if List.mem t l
                       then loop (n+1)
                       else t
  in loop 0
;;


(* função de substituição: implementa {e/x}t *)
let rec subs (e:term) (x:string) (t:term) : term =
  match t with
  | Num(n)                 -> Num(n)
  | Bool(b)                -> Bool(b)
  | Binop(op,t1,t2)        -> Binop(op, subs e x t1, subs e x t2)
  | If(t1,t2,t3)           -> If(subs e x t1, subs e x t2, subs e x t3)
  | Var(y) when x=y        -> e
  | Var(y) when x<>y       -> Var(y)
  | App(t1,t2)             -> App(subs e x t1, subs e x t2)
  | Fun(y,tp,t1) when x=y  -> Fun(y,tp,t1)
  | Fun(y,tp,t1) when x<>y -> let z = newVar (union (union (fv e) (fv t1)) [x;y])
                              in  Fun(z,tp, subs e x (subs (Var(z)) y t1))
  | Let(y,tp,t1,t2) when x=y  -> Let(y,tp, subs e x t1,t2)
  | Let(y,tp,t1,t2) when x<>y -> let z = newVar (union (union (fv e) (fv t2)) [x;y])
                                 in  Let(z,tp, subs e x t1, subs e x (subs (Var(z)) y t2))
;;



(* testa se um termo é valor *)
let value (t:term) : bool =
  match t  with
  | Num(_)     -> true
  | Bool(_)    -> true
  | Fun(_,_,_) -> true
  | _          -> false
;;

(* testa se um termo não é valor *)
let not_value x = not (value x) ;;



(* função semântica small-step: implementa um passo de transição (quando há) *)
let rec step (t:term) : term option =
  match t with
  | Num(_)  -> None
  | Bool(_) -> None
  | Binop(op,t1,t2) when not_value t1 ->
               (match step t1 with
                |  None -> None
                |  Some(t') -> Some(Binop(op,t',t2)) )
  | Binop(op,t1,t2) when not_value t2 ->
               (match step t2 with
	            | None -> None
                | Some(t') -> Some(Binop(op,t1,t')) )
  | Binop(Plus,Num(n1),Num(n2)) -> Some(Num(n1+n2))
  | Binop(Geq,Num(n1),Num(n2))  -> Some(Bool(n1>=n2))
  | Binop(_,_,_) -> None
  | If(p,t1,t2) when not_value p ->
               (match step p with
	            | None -> None
                | Some(p') -> Some(If(p',t1,t2)) )
  | If(Bool(true),t1,t2) -> Some(t1)
  | If(Bool(false),t1,t2) -> Some(t2)
  | If(_,_,_) -> None
  | Var(_) -> None
  | Fun(_,_,_) -> None
  | App(t1,t2) when not_value t1 ->
               (match step t1 with
                |  None -> None
                |  Some(t') -> Some(App(t',t2)) )
  | App(t1,t2) when not_value t2 ->
               (match step t2 with
                |  None -> None
                |  Some(t') -> Some(App(t1,t')) )
  | App(Fun(x,tp,e),t2) -> Some(subs t2 x e)
  | App(_,_) -> None
  | Let(x,tp,t1,t2) when not_value t1 ->
               (match step t1 with
                |  None -> None
                |  Some(t') -> Some(Let(x,tp,t',t2)) )
  | Let(x,tp,t1,t2) when not_value t2 ->
               (match step t2 with
                |  None -> None
                |  Some(t') -> Some(Let(x,tp,t1,t')) )
  | Let(x,tp,t1,t2) -> Some(subs t1 x t2)


(* função que avalia um termo até não haver mais progresso possível *)
let rec eval (t:term) : term =
  match step t with
  | None -> t
  | Some(t') -> eval(t')
;;