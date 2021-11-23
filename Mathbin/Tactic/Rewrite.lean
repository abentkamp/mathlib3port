import Leanbin.Data.Dlist 
import Mathbin.Tactic.Core

namespace Tactic

open Expr List

unsafe def match_fn (fn : expr) : expr → tactic (expr × expr)
| app (app fn' e₀) e₁ => unify fn fn' $> (e₀, e₁)
| _ => failed

unsafe def fill_args : expr → tactic (expr × List expr)
| pi n bi d b =>
  do 
    let v ← mk_meta_var d 
    let (r, vs) ← fill_args (b.instantiate_var v)
    return (r, v :: vs)
| e => return (e, [])

unsafe def mk_assoc_pattern' (fn : expr) : expr → tactic (Dlist expr)
| e =>
  (do 
      let (e₀, e₁) ← match_fn fn e
      (· ++ ·) <$> mk_assoc_pattern' e₀ <*> mk_assoc_pattern' e₁) <|>
    pure (Dlist.singleton e)

unsafe def mk_assoc_pattern (fn e : expr) : tactic (List expr) :=
  Dlist.toList <$> mk_assoc_pattern' fn e

unsafe def mk_assoc (fn : expr) : List expr → tactic expr
| [] => failed
| [x] => pure x
| x₀ :: x₁ :: xs => mk_assoc (fn x₀ x₁ :: xs)

unsafe def chain_eq_trans : List expr → tactic expr
| [] => to_expr (pquote.1 rfl)
| [e] => pure e
| e :: es => chain_eq_trans es >>= mk_eq_trans e

unsafe def unify_prefix : List expr → List expr → tactic Unit
| [], _ => pure ()
| _, [] => failed
| x :: xs, y :: ys => unify x y >> unify_prefix xs ys

unsafe def match_assoc_pattern' (p : List expr) : List expr → tactic (List expr × List expr)
| es =>
  unify_prefix p es $> ([], es.drop p.length) <|>
    match es with 
    | [] => failed
    | x :: xs => Prod.mapₓ (cons x) id <$> match_assoc_pattern' xs

unsafe def match_assoc_pattern (fn p e : expr) : tactic (List expr × List expr) :=
  do 
    let p' ← mk_assoc_pattern fn p 
    let e' ← mk_assoc_pattern fn e 
    match_assoc_pattern' p' e'

unsafe def mk_eq_proof (fn : expr) (e₀ e₁ : List expr) (p : expr) : tactic (expr × expr × expr) :=
  do 
    let (l, r) ← infer_type p >>= match_eq 
    if e₀.empty ∧ e₁.empty then pure (l, r, p) else
        do 
          let l' ← mk_assoc fn (e₀ ++ [l] ++ e₁)
          let r' ← mk_assoc fn (e₀ ++ [r] ++ e₁)
          let t ← infer_type l' 
          let v ← mk_local_def `x t 
          let e ← mk_assoc fn (e₀ ++ [v] ++ e₁)
          let p ← mk_congr_arg (e.lambdas [v]) p 
          let p' ← mk_id_eq l' r' p 
          return (l', r', p')

unsafe def assoc_root (fn assoc : expr) : expr → tactic (expr × expr)
| e =>
  (do 
      let (e₀, e₁) ← match_fn fn e 
      let (ea, eb) ← match_fn fn e₁ 
      let e' := fn (fn e₀ ea) eb 
      let p' ← mk_eq_symm (assoc e₀ ea eb)
      let (e'', p'') ← assoc_root e' 
      Prod.mk e'' <$> mk_eq_trans p' p'') <|>
    Prod.mk e <$> mk_eq_refl e

unsafe def assoc_refl' (fn assoc : expr) : expr → expr → tactic expr
| l, r =>
  is_def_eq l r >> mk_eq_refl l <|>
    do 
      let (l', l_p) ← assoc_root fn assoc l <|> fail "A"
      let (el₀, el₁) ← match_fn fn l' <|> fail "B"
      let (r', r_p) ← assoc_root fn assoc r <|> fail "C"
      let (er₀, er₁) ← match_fn fn r' <|> fail "D"
      let p₀ ← assoc_refl' el₀ er₀ 
      let p₁ ← is_def_eq el₁ er₁ >> mk_eq_refl el₁ 
      let f_eq ← mk_congr_arg fn p₀ <|> fail "G"
      let p' ← mk_congr f_eq p₁ <|> fail "H"
      let r_p' ← mk_eq_symm r_p 
      chain_eq_trans [l_p, p', r_p']

unsafe def assoc_refl (fn : expr) : tactic Unit :=
  do 
    let (l, r) ← target >>= match_eq 
    let assoc ← mk_mapp `` IsAssociative.assoc [none, fn, none] <|> fail f! "{fn } is not associative"
    assoc_refl' fn assoc l r >>= tactic.exact

unsafe def flatten (fn assoc e : expr) : tactic (expr × expr) :=
  do 
    let ls ← mk_assoc_pattern fn e 
    let e' ← mk_assoc fn ls 
    let p ← assoc_refl' fn assoc e e' 
    return (e', p)

unsafe def assoc_rewrite_intl (assoc h e : expr) : tactic (expr × expr) :=
  do 
    let t ← infer_type h 
    let (lhs, rhs) ← match_eq t 
    let fn := lhs.app_fn.app_fn 
    let (l, r) ← match_assoc_pattern fn lhs e 
    let (lhs', rhs', h') ← mk_eq_proof fn l r h 
    let e_p ← assoc_refl' fn assoc e lhs' 
    let (rhs'', rhs_p) ← flatten fn assoc rhs' 
    let final_p ← chain_eq_trans [e_p, h', rhs_p]
    return (rhs'', final_p)

unsafe def enum_assoc_subexpr' (fn : expr) : expr → tactic (Dlist expr)
| e =>
  Dlist.singleton e <$ (match_fn fn e >> guardₓ ¬e.has_var) <|>
    expr.mfoldl (fun es e' => (· ++ es) <$> enum_assoc_subexpr' e') Dlist.empty e

unsafe def enum_assoc_subexpr (fn e : expr) : tactic (List expr) :=
  Dlist.toList <$> enum_assoc_subexpr' fn e

unsafe def mk_assoc_instance (fn : expr) : tactic expr :=
  do 
    let t ← mk_mapp `` IsAssociative [none, fn]
    let inst ←
      Prod.snd <$> solve_aux t assumption <|> mk_instance t >>= assertv `_inst t <|> fail f! "{fn } is not associative"
    mk_mapp `` IsAssociative.assoc [none, fn, inst]

unsafe def assoc_rewrite (h e : expr) (opt_assoc : Option expr := none) : tactic (expr × expr × List expr) :=
  do 
    let (t, vs) ← infer_type h >>= fill_args 
    let (lhs, rhs) ← match_eq t 
    let fn := lhs.app_fn.app_fn 
    let es ← enum_assoc_subexpr fn e 
    let assoc ←
      match opt_assoc with 
        | none => mk_assoc_instance fn
        | some assoc => pure assoc 
    let (_, p) ← mfirst (assoc_rewrite_intl assoc$ h.mk_app vs) es 
    let (e', p', _) ← tactic.rewrite p e 
    pure (e', p', vs)

unsafe def assoc_rewrite_target (h : expr) (opt_assoc : Option expr := none) : tactic Unit :=
  do 
    let tgt ← target 
    let (tgt', p, _) ← assoc_rewrite h tgt opt_assoc 
    replace_target tgt' p

unsafe def assoc_rewrite_hyp (h hyp : expr) (opt_assoc : Option expr := none) : tactic expr :=
  do 
    let tgt ← infer_type hyp 
    let (tgt', p, _) ← assoc_rewrite h tgt opt_assoc 
    replace_hyp hyp tgt' p

namespace Interactive

setup_tactic_parser

private unsafe def assoc_rw_goal (rs : List rw_rule) : tactic Unit :=
  rs.mmap'$
    fun r =>
      do 
        save_info r.pos 
        let eq_lemmas ← get_rule_eqn_lemmas r 
        orelse'
            (do 
              let e ← to_expr' r.rule 
              assoc_rewrite_target e)
            (eq_lemmas.mfirst$
              fun n =>
                do 
                  let e ← mk_const n 
                  assoc_rewrite_target e)
            eq_lemmas.empty

private unsafe def uses_hyp (e : expr) (h : expr) : Bool :=
  e.fold ff$ fun t _ r => r || t = h

private unsafe def assoc_rw_hyp : List rw_rule → expr → tactic Unit
| [], hyp => skip
| r :: rs, hyp =>
  do 
    save_info r.pos 
    let eq_lemmas ← get_rule_eqn_lemmas r 
    orelse'
        (do 
          let e ← to_expr' r.rule 
          when ¬uses_hyp e hyp$ assoc_rewrite_hyp e hyp >>= assoc_rw_hyp rs)
        (eq_lemmas.mfirst$
          fun n =>
            do 
              let e ← mk_const n 
              assoc_rewrite_hyp e hyp >>= assoc_rw_hyp rs)
        eq_lemmas.empty

private unsafe def assoc_rw_core (rs : parse rw_rules) (loca : parse location) : tactic Unit :=
  (match loca with 
      | loc.wildcard => loca.try_apply (assoc_rw_hyp rs.rules) (assoc_rw_goal rs.rules)
      | _ => loca.apply (assoc_rw_hyp rs.rules) (assoc_rw_goal rs.rules)) >>
      try reflexivity >>
    try (returnopt rs.end_pos >>= save_info)

/--
`assoc_rewrite [h₀,← h₁] at ⊢ h₂` behaves like `rewrite [h₀,← h₁] at ⊢ h₂`
with the exception that associativity is used implicitly to make rewriting
possible.

It works for any function `f` for which an `is_associative f` instance can be found.

```
example {α : Type*} (f : α → α → α) [is_associative α f] (a b c d x : α) :
  let infix `~` := f in
  b ~ c = x → (a ~ b ~ c ~ d) = (a ~ x ~ d) :=
begin
  intro h,
  assoc_rw h,
end
```
-/
unsafe def assoc_rewrite (q : parse rw_rules) (l : parse location) : tactic Unit :=
  propagate_tags (assoc_rw_core q l)

/-- synonym for `assoc_rewrite` -/
unsafe def assoc_rw (q : parse rw_rules) (l : parse location) : tactic Unit :=
  assoc_rewrite q l

add_tactic_doc
  { Name := "assoc_rewrite", category := DocCategory.tactic,
    declNames := [`tactic.interactive.assoc_rewrite, `tactic.interactive.assoc_rw], tags := ["rewriting"],
    inheritDescriptionFrom := `tactic.interactive.assoc_rewrite }

end Interactive

end Tactic

