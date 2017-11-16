/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Mario Carneiro
-/
prelude
import init.data.ordering

universes u v

inductive rbnode (α : Type u)
| leaf  {}                                                 : rbnode
| red_node   (lchild : rbnode) (val : α) (rchild : rbnode) : rbnode
| black_node (lchild : rbnode) (val : α) (rchild : rbnode) : rbnode

namespace rbnode
variables {α : Type u} {β : Type v}

inductive color
| red | black

open color nat

instance color.decidable_eq : decidable_eq color :=
λ a b, color.cases_on a
  (color.cases_on b (is_true rfl) (is_false (λ h, color.no_confusion h)))
  (color.cases_on b (is_false (λ h, color.no_confusion h)) (is_true rfl))

def fold (f : α → β → β) : rbnode α → β → β
| leaf b               := b
| (red_node l v r)   b := fold r (f v (fold l b))
| (black_node l v r) b := fold r (f v (fold l b))

def rev_fold (f : α → β → β) : rbnode α → β → β
| leaf b               := b
| (red_node l v r)   b := rev_fold l (f v (rev_fold r b))
| (black_node l v r) b := rev_fold l (f v (rev_fold r b))

def balance1 : rbnode α → α → rbnode α → α → rbnode α → rbnode α
| (red_node l x r₁) y r₂  v t := red_node (black_node l x r₁) y (black_node r₂ v t)
| l₁ y (red_node l₂ x r)  v t := red_node (black_node l₁ y l₂) x (black_node r v t)
| l  y r                  v t := black_node (red_node l y r) v t

def balance1_node : rbnode α → α → rbnode α → rbnode α
| (red_node l x r)   v t := balance1 l x r v t
| (black_node l x r) v t := balance1 l x r v t
| leaf               v t := t  /- dummy value -/

def balance2 : rbnode α → α → rbnode α → α → rbnode α → rbnode α
| (red_node l x₁ r₁) y r₂  v t := red_node (black_node t v l) x₁ (black_node r₁ y r₂)
| l₁ y (red_node l₂ x₂ r₂) v t := red_node (black_node t v l₁) y (black_node l₂ x₂ r₂)
| l  y r                   v t := black_node t v (red_node l y r)

def balance2_node : rbnode α → α → rbnode α → rbnode α
| (red_node l x r)   v t := balance2 l x r v t
| (black_node l x r) v t := balance2 l x r v t
| leaf               v t := t /- dummy -/

def get_color : rbnode α → color
| (red_node _ _ _) := red
| _                := black

section insert

variables (lt : α → α → Prop) [decidable_rel lt]

def ins : rbnode α → α → rbnode α
| leaf             x  := red_node leaf x leaf
| (red_node a y b) x  :=
   match cmp_using lt x y with
   | ordering.lt := red_node (ins a x) y b
   | ordering.eq := red_node a x b
   | ordering.gt := red_node a y (ins b x)
   end
| (black_node a y b) x :=
    match cmp_using lt x y with
    | ordering.lt :=
      if a.get_color = red then balance1_node (ins a x) y b
      else black_node (ins a x) y b
    | ordering.eq := black_node a x b
    | ordering.gt :=
      if b.get_color = red then balance2_node (ins b x) y a
      else black_node a y (ins b x)
    end

def insert (t : rbnode α) (x : α) : rbnode α :=
let r := ins lt t x in
match r with
| red_node l v r := black_node l v r
| _              := r
end

end insert

section membership

variables (lt : α → α → Prop) [decidable_rel lt]

def contains : rbnode α → α → bool
| leaf             x := ff
| (red_node a y b) x :=
  match cmp_using lt x y with
  | ordering.lt := contains a x
  | ordering.eq := tt
  | ordering.gt := contains b x
  end
| (black_node a y b) x :=
  match cmp_using lt x y with
  | ordering.lt := contains a x
  | ordering.eq := tt
  | ordering.gt := contains b x
  end

protected def mem : α → rbnode α → Prop
| a leaf               := false
| a (red_node l v r)   := mem a l ∨ cmp_using lt a v = ordering.eq  ∨ mem a r
| a (black_node l v r) := mem a l ∨ cmp_using lt a v = ordering.eq  ∨ mem a r

end membership

inductive well_formed (lt : α → α → Prop) : rbnode α → Prop
| leaf_wff : well_formed leaf
| insert_wff {n : rbnode α} (x : α) [decidable_rel lt] : well_formed n → well_formed (insert lt n x)

end rbnode

open rbnode

set_option auto_param.check_exists false

def rbtree (α : Type u) (lt : α → α → Prop . rbtree.default_lt) [decidable_rel lt] : Type u :=
{t : rbnode α // t.well_formed lt }

def mk_rbtree (α : Type u) (lt : α → α → Prop . rbtree.default_lt) [decidable_rel lt] : rbtree α lt :=
⟨leaf, well_formed.leaf_wff lt⟩

namespace rbtree
variables {α : Type u} {lt : α → α → Prop} [decidable_rel lt]

def to_list : rbtree α lt → list α
| ⟨t, _⟩ := t.rev_fold (::) []

def insert : rbtree α lt → α → rbtree α lt
| ⟨t, w⟩   x := ⟨t.insert lt x, well_formed.insert_wff x w⟩

def contains : rbtree α lt → α → bool
| ⟨t, _⟩ x := t.contains lt x

protected def mem (a : α) (t : rbtree α lt) : Prop :=
rbnode.mem lt a t.val

instance : has_mem α (rbtree α lt) :=
⟨rbtree.mem⟩

def from_list (l : list α) (lt : α → α → Prop . rbtree.default_lt) [decidable_rel lt] : rbtree α lt :=
l.foldl insert (mk_rbtree α lt)

instance [has_repr α] : has_repr (rbtree α lt) :=
⟨λ t, "rbtree_of " ++ repr t.to_list⟩

end rbtree

def rbtree_of {α : Type u} (l : list α) (lt : α → α → Prop . rbtree.default_lt) [decidable_rel lt] : rbtree α lt :=
rbtree.from_list l lt