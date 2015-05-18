-- Marcell van Geest (3824985)

module Exercise1 where

{- Instruction: Fill in all the missing definitions. In most cases,
the type signature enforces that there should be a single unique
definition that fits. 

If you have any questions, don't hesitate to email me or ask in class.
-}


---------------------
------ Prelude ------
---------------------

data Bool : Set where
  True : Bool
  False : Bool

data Nat : Set where
  Zero : Nat 
  Succ : Nat -> Nat

{-# BUILTIN NATURAL Nat #-}

_+_ : Nat -> Nat -> Nat
Zero + m = m
Succ k + m = Succ (k + m)

_*_ : Nat -> Nat -> Nat
Zero * n = Zero
(Succ k) * n = n + (k * n)

data List (a : Set) : Set where
  Nil : List a
  Cons : a -> List a -> List a

data Vec (a : Set) : Nat -> Set where
  Nil : Vec a 0
  Cons : {n : Nat} -> (x : a) -> (xs : Vec a n) -> Vec a (Succ n)

head : {a : Set} {n : Nat}-> Vec a (Succ n) -> a
head (Cons x xs) = x

append : {a : Set} {n m : Nat} -> Vec a n -> Vec a m -> Vec a (n + m)
append Nil ys = ys
append (Cons x xs) ys = Cons x (append xs ys)

data _==_ {a : Set} (x : a) : a -> Set where
  Refl : x == x

cong : {a b : Set} {x y : a} -> (f : a -> b) -> x == y -> f x == f y
cong f Refl = Refl

data Unit : Set where
  unit : Unit

data Empty : Set where

magic : {a : Set} -> Empty -> a
magic ()

data Pair (a b : Set) : Set where
  _,_ : a -> b -> Pair a b

data Fin : Nat -> Set where
  Fz : forall {n} -> Fin (Succ n)
  Fs : forall {n} -> Fin n -> Fin (Succ n)

data Maybe (a : Set) : Set where
  Just : a -> Maybe a
  Nothing : Maybe a

----------------------
----- Exercise 1 -----
----------------------

--Show that the Vec a n type is applicative

pure : {n : Nat} {a : Set} -> a -> Vec a n
pure {Zero} x = Nil
pure {Succ n} x = Cons x (pure x)

_<*>_ : {a b : Set} {n : Nat} -> Vec (a -> b) n -> Vec a n -> Vec b n
_<*>_ {n = Zero} Nil Nil = Nil
_<*>_ {n = Succ n} (Cons f fs) (Cons x xs) = Cons (f x) (fs <*> xs)

-- The Functorness of Applicatives! Or so I've been told.
vmap : {a b : Set} {n : Nat} -> (a -> b) -> Vec a n -> Vec b n
vmap f xs = pure f <*> xs

-- Alternatively, a direct definition:
vmap' : {a b : Set} {n : Nat} -> (a -> b) -> Vec a n -> Vec b n
vmap' {n = Zero} _ Nil = Nil
vmap' {n = Succ n} f (Cons x xs) = Cons (f x) (vmap' f xs)

-- Just to check if they're really the same...
vmaps-equal : {a b : Set} {n : Nat} {v : Vec a n} {f : a -> b} ->
  vmap f v == vmap' f v
vmaps-equal {n = Zero} {v = Nil} = Refl
vmaps-equal {n = Succ n} {v = Cons x v'} {f = f} =
  cong (Cons (f x)) vmaps-equal

----------------------
----- Exercise 2 -----
----------------------

-- Using the Vector definitions, define a type for matrices;
-- matrix addition; the identity matrix; and matrix transposition.

Matrix : Set -> Nat -> Nat -> Set
Matrix a n m = Vec (Vec a n) m 

-- Define matrix addition
madd : {n m : Nat} -> Matrix Nat m n -> Matrix Nat m n -> Matrix Nat m n
madd Nil Nil = Nil
madd (Cons xs xss) (Cons ys yss) = Cons (vadd xs ys) (madd xss yss)
  where 
    vadd : {m : Nat} -> Vec Nat m -> Vec Nat m -> Vec Nat m
    vadd Nil Nil = Nil
    vadd (Cons x xs) (Cons y ys) = Cons (x + y) (vadd xs ys)

-- Define the identity matrix
idMatrix : {n : Nat} -> Matrix Nat n n
idMatrix {n} = pure (pure n)

-- Analogous to head
tail : {a : Set} {n : Nat} -> Vec a (Succ n) -> Vec a n
tail (Cons x xs) = xs

-- Define matrix transposition
transpose : {n m : Nat} {a : Set} -> Matrix a m n -> Matrix a n m
transpose Nil = pure Nil
transpose (Cons Nil xss) = Nil
transpose (Cons (Cons x xs) xss) = Cons (Cons x (vmap head xss)) (transpose (Cons xs (vmap tail xss)))

----------------------
----- Exercise 3 -----
----------------------

-- Define a few functions manipulating finite types.

-- The result of "plan {n}" should be a vector of length n storing all
-- the inhabitants of Fin n in increasing order.
plan : {n : Nat} -> Vec (Fin n) n
plan {Zero} = Nil
plan {Succ n} = Cons Fz (vmap Fs plan)

-- Define a forgetful map, mapping Fin to Nat
forget : {n : Nat} -> Fin n -> Nat
forget Fz = Zero
forget (Fs i) = Succ (forget i)

-- There are several ways to embed Fin n in Fin (Succ n).  Try to come
-- up with one that satisfies the correctness property below (and
-- prove that it does).
embed : {n : Nat} -> Fin n -> Fin (Succ n)
embed Fz = Fz
embed (Fs i) = Fs (embed i)

correct : {n : Nat} -> (i : Fin n) -> forget i == forget (embed i)
correct Fz = Refl
correct (Fs i) = cong Succ (correct i)

----------------------
----- Exercise 4 -----
----------------------

-- Given the following data type definition:

data Compare : Nat -> Nat -> Set where
  LessThan : forall {n} k -> Compare n (n + Succ k)
  Equal : forall {n} -> Compare n n
  GreaterThan : forall {n} k -> Compare (n + Succ k) n

-- Show that there is a 'covering function'
cmp : (n m : Nat) -> Compare n m 
cmp Zero Zero = Equal
cmp Zero (Succ m) = LessThan m
cmp (Succ n) Zero = GreaterThan n
cmp (Succ n) (Succ m) with cmp n m
cmp (Succ n) (Succ .(n + Succ k)) | LessThan k = LessThan k
cmp (Succ n) (Succ .n) | Equal = Equal
cmp (Succ .(m + Succ k)) (Succ m) | GreaterThan k = GreaterThan k

-- Use the cmp function you defined above to define the absolute
-- difference between two natural numbers.
difference : (n m : Nat) -> Nat
difference n m with cmp n m 
difference n .(n + Succ k) | LessThan k = (Succ k)
difference n .n | Equal = Zero
difference .(m + Succ k) m | GreaterThan k = Succ k

----------------------
----- Exercise 5 -----
----------------------

-- Prove the following equalities.  You may want to define auxiliary
-- lemmas or use the notation intoduced in the lectures.

sym : {a : Set} {x y : a} -> x == y -> y == x
sym Refl = Refl

trans : {a : Set} {x y z : a} -> x == y -> y == z -> x == z
trans Refl Refl = Refl

plusZero : (n : Nat) -> (n + 0) == n
plusZero Zero = Refl
plusZero (Succ n) = cong Succ (plusZero n)

plusSucc : (n m : Nat) -> Succ (n + m) == (n + Succ m)
plusSucc Zero m = Refl
plusSucc (Succ n) m = cong Succ (plusSucc n m)

plusCommutes : (n m : Nat) -> (n + m) == (m + n)
plusCommutes Zero m = sym (plusZero m)
plusCommutes (Succ n) m = trans (cong Succ (plusCommutes n m)) (plusSucc m n)

plusAssociates : (n m k : Nat) -> ((n + m) + k) == (n + (m + k))
plusAssociates Zero m k = Refl
plusAssociates (Succ n) m k = cong Succ (plusAssociates n m k)

-- Not the prettiest proof, but writing out each step
-- makes it even less readable.
distributivity : (n m k : Nat) -> (n * (m + k)) == ((n * m) + (n * k))
distributivity Zero m k = Refl
distributivity (Succ n) m k = sym
  (trans (plusAssociates m (n * m) (k + (n * k)))
  (trans (cong (λ p → m + p) (sym (plusAssociates (n * m) k (n * k))))
  (trans (cong (λ p → m + (p + (n * k))) (plusCommutes (n * m) k))
  (trans (cong (λ p → m + p) (plusAssociates k (n * m) (n * k)))
  (trans (sym (plusAssociates m k ((n * m) + (n * k))))
  (trans (cong (λ p → (m + k) + p) (sym (distributivity n m k))) Refl))))))

----------------------
----- Exercise 6 -----
----------------------

-- Prove that the sublist relation defined below is transitive and reflexive.

data SubList {a : Set} : List a -> List a -> Set where
  Base : SubList Nil Nil
  Keep : forall {x xs ys} -> SubList xs ys -> SubList (Cons x xs) (Cons x ys)
  Drop : forall {y zs ys} -> SubList zs ys -> SubList zs (Cons y ys)

SubListRefl : {a : Set} {xs : List a} -> SubList xs xs
SubListRefl {xs = Nil} = Base
SubListRefl {xs = Cons x xs} = Keep SubListRefl

SubListTrans : {a : Set} {xs ys zs : List a} -> SubList xs ys -> SubList ys zs -> SubList xs zs
SubListTrans Base Base = Base
SubListTrans p (Drop q) = Drop (SubListTrans p q)
SubListTrans (Keep p) (Keep q) = Keep (SubListTrans p q)
SubListTrans (Drop p) (Keep q) = Drop (SubListTrans p q)

-- The following three-lemma proof cannot be the most elegant,
-- but at least it shows that cases other than Base-Base and 
-- Keep-Keep are impossible in SubListAntiSym.

lem-SubListUnCons : {a : Set} {x : a} {xs ys : List a} -> SubList (Cons x xs) ys -> SubList xs ys
lem-SubListUnCons (Keep p) = Drop p
lem-SubListUnCons (Drop p) = Drop (lem-SubListUnCons p)

lem-SubListStepDown : {a : Set} {x y : a} {xs ys : List a} -> SubList (Cons x xs) (Cons y ys) -> SubList xs ys
lem-SubListStepDown (Keep p) = p
lem-SubListStepDown (Drop p) = lem-SubListUnCons p

lem-SubListNotLarger : {a : Set} {x : a} {xs : List a} -> SubList (Cons x xs) xs -> Empty
lem-SubListNotLarger {xs = Nil} ()
lem-SubListNotLarger {xs = Cons x xs} p = lem-SubListNotLarger (lem-SubListStepDown p)

SubListAntiSym : {a : Set} {xs ys : List a} ->  SubList xs ys -> SubList ys xs -> xs == ys
SubListAntiSym Base Base = Refl
SubListAntiSym {xs = Cons x xs} {ys = Cons .x ys} (Keep p) (Keep q) = cong (Cons x) (SubListAntiSym p q)
SubListAntiSym p (Drop q) = magic (lem-SubListNotLarger (SubListTrans p q))
SubListAntiSym (Drop p) (Keep q) = magic (lem-SubListNotLarger (SubListTrans p q))

----------------------
----- Exercise 7 -----
----------------------

-- Define the constructors of a data type 
data LEQ : Nat -> Nat -> Set where
  Base : {n : Nat} -> LEQ Zero n
  Step : {n m : Nat} -> LEQ n m -> LEQ (Succ n) (Succ m)

-- (Alternative correct definitions exist - this one is the easiest to
-- work with for the rest of this exercise)

leqRefl : (n : Nat) -> LEQ n n
leqRefl Zero = Base
leqRefl (Succ n) = Step (leqRefl n)

leqTrans : {n m k : Nat} -> LEQ n m -> LEQ m k -> LEQ n k
leqTrans Base q = Base
leqTrans (Step p) (Step q) = Step (leqTrans p q)

leqAntiSym : {n m : Nat} -> LEQ n m -> LEQ m n -> n == m
leqAntiSym Base Base = Refl
leqAntiSym (Step p) (Step q) = cong Succ (leqAntiSym p q)

-- Given the following function:
_<=_ : Nat -> Nat -> Bool
Zero <= y = True
Succ x <= Zero = False
Succ x <= Succ y = x <= y

-- Now show that this function behaves as the LEQ data type

leq<= : {n m : Nat} -> LEQ n m -> (n <= m) == True
leq<= Base = Refl
leq<= (Step p) = leq<= p

<=leq : (n m : Nat) -> (n <= m) == True -> LEQ n m
<=leq Zero m Refl = Base
<=leq (Succ n) Zero ()
<=leq (Succ n) (Succ m) p = Step (<=leq n m p)

----------------------
----- Exercise 7 -----
----------------------

-- We can define negation as follows
Not : Set -> Set
Not P = P -> Empty

-- Agda's logic is *constructive*, meaning some properties you may be
-- familiar with from classical logic do not hold.

notNotP : {P : Set} -> P -> Not (Not P)
notNotP P = λ Q → Q P

-- The reverse does not hold: Not (Not P) does not imply P

-- Similarly, P or Not P doesn't hold for all statements P, but we can
-- prove the statement below. It's an amusing brainteaser.

data Or (a b : Set) : Set where
  Inl : a -> Or a b
  Inr : b -> Or a b

orCase : {a b c : Set} -> (a -> c) -> (b -> c) -> Or a b -> c
orCase f g (Inl x) = f x
orCase f g (Inr x) = g x

notNotExcludedMiddle : {P : Set} -> Not (Not (Or P (Not P)))
notNotExcludedMiddle = λ Q → Q (Inr (λ R → Q (Inl R))) 

-- There are various different axioms that can be added to a
-- constructive logic to get the more familiar classical logic.

doubleNegation = {P : Set} -> Not (Not P) -> P
excludedMiddle = {P : Set} -> Or P (Not P)
impliesToOr = {P Q : Set} -> (P -> Q) -> Or (Not P) Q

-- Let's try to prove these three statements are equivalent...  you
--  may find it helpful to replace the 'doubleNegation' and others
--  with their definition in the type signatures below.
--  This is not always easy...

step1 : doubleNegation -> excludedMiddle
step1 dn = dn notNotExcludedMiddle

step2 : excludedMiddle -> impliesToOr
step2 em {P} {Q} with em {P}
step2 em | Inl p = λ iPQ → Inr (iPQ p)
step2 em | Inr np = λ _ → Inl np

step3 : impliesToOr -> doubleNegation
step3 ito {P} h with ito {P} {P} (λ p → p)
step3 ito h | Inl np = magic (h np)
step3 ito h | Inr p = p

-- HARDER: show that these are equivalent to Peirces law:
-- NB. The unfortunate guy's name is Peirce, not Pierce ;)
peircesLaw = {P Q : Set} -> ((P -> Q) -> P) -> P

step4 : excludedMiddle -> peircesLaw
step4 em {P} {Q} s with em {P}
step4 em s | Inl p = p
step4 em {P} {Q} s | Inr np = s (λ p → magic (np p))

step4' : peircesLaw -> excludedMiddle
step4' pl {P} = pl {Or P (Not P)} {Empty} (λ nPonP → Inr (λ p → nPonP (Inl p)))

-- (the other equivalences now hold because of the first three steps
-- and transitivity)

----------------------
----- Exercise 9 -----
----------------------

-- Here is a data type for 'Raw' lambda terms that have not yet
--   been type checked.

data Raw : Set where
  Lam : Raw -> Raw
  App : Raw -> Raw -> Raw
  Var : Nat -> Raw

-- The Agda tutorial shows how to define a type for the well-typed
--   lambda terms, and a type checker mapping Raw terms to well-typed
--   terms (or an error)
--
-- Adapt their development to instead restrict yourself to
-- 'scope checking' -- i.e. give a data type for the well-scoped
-- lambda terms and a function that maps a raw term to a well-scoped
-- lambda term.
--
-- This makes it possible to represent ill-typed terms such as (\x . x
-- x).

-- The Bounds data type from the lecture,
-- with (k + bound) reversed for ease of use
data Bounds (bound : Nat) : Nat -> Set where
  InBounds : (i : Fin bound) -> Bounds bound (forget i)
  OutOfBounds : (k : Nat) -> Bounds bound (bound + k)

-- The checkBound function mentioned (but not defined)
-- in the lecture
checkBound : (bound : Nat) -> (x : Nat) -> Bounds bound x
checkBound Zero x = OutOfBounds x
checkBound (Succ bound) Zero = InBounds Fz
checkBound (Succ bound) (Succ x) with checkBound bound x
checkBound (Succ bound) (Succ .(forget i)) | InBounds i = InBounds (Fs i)
checkBound (Succ bound) (Succ .(bound + k)) | OutOfBounds k = OutOfBounds k

-- The only difference between the tutorial's development and this
-- adapted one is that instead of remembering the *types* of
-- the bindings in the context, we only remember *how many* we have.
Context = Nat

-- A Var is well-scoped if it points to a binding strictly inside
-- the context (the Zero context is not a binding itself).
-- Fin Γ is equivalent to a γ alongside a proof that LT γ Γ,
-- but we haven't defined LT (less than) yet (only LEQ).
-- The LT γ Γ would play the role of the τ ∈ Γ proof in the 
-- development of the tutorial.
data Term (Γ : Context) : Set where
  Lam : Term (Succ Γ) -> Term Γ
  App : Term Γ -> Term Γ -> Term Γ
  Var : Fin Γ -> Term Γ

erase : {Γ : Context} -> Term Γ -> Raw
erase (Lam t) = Lam (erase t)
erase (App t u) = App (erase t) (erase u)
erase (Var i) = Var (forget i)

data Infer (Γ : Context) : Raw -> Set where
  good : (τ : Term Γ) -> Infer Γ (erase τ)
  bad : {e : Raw} -> Infer Γ e

infer : (Γ : Context)(e : Raw) -> Infer Γ e
infer Γ (Lam e) with infer (Succ Γ) e
infer Γ (Lam .(erase τ)) | good τ = good (Lam τ)
infer Γ (Lam e) | bad = bad
infer Γ (App et eu) with infer Γ et | infer Γ eu
infer Γ (App .(erase τₜ) .(erase τᵤ)) | good τₜ | good τᵤ = good (App τₜ τᵤ)
infer Γ (App et eu) | _ | _ = bad
infer Γ (Var x) with checkBound Γ x 
infer Γ (Var .(forget i)) | InBounds i = good (Var i)
infer Γ (Var .(Γ + k)) | OutOfBounds k = bad

-- A representation of \x . x x
xxRaw : Raw
xxRaw = Lam (App (Var Zero) (Var Zero))

-- xxRaw can be inferred
xxWellScoped : infer Zero xxRaw == good (Lam (App (Var Fz) (Var Fz)))
xxWellScoped = Refl

-- Some non-well-scoped term
xxyRaw : Raw
xxyRaw = Lam (App (Var Zero) (App (Var Zero) (Var (Succ Zero))))

-- xyRaw cannot be inferred
xxyNotWellScoped : infer Zero xxyRaw == bad
xxyNotWellScoped = Refl
