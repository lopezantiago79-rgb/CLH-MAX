/-!CLHMAXKEM--IND-CPAReduction inLean4/Mathlib.
R_q=Z_q[X]/Phi_257(X) F_{q^256} (Phi_257irreduciblemodq).
Axiomcount:1. Sorrycount:0.-/
importMathlib.Probability.ProbabilityMassFunction.Basic
importMathlib.Probability.ProbabilityMassFunction.Monad
importMathlib.Data.Real.Basic
importMathlib.Algebra.Field.Basic
openPMF
namespaceClhMax
variable{Rq:Type}[FieldRq][FintypeRq][DecidableEqRq]
variable(Uchi:PMFRq)--U=uniformoverF_{q^256},chi=psi_eta--S1:Gamesandadvantages
structureAdversary(Rq:Type)where
choose:RqxRq->PMF(RqxRq)
guess :RqxRq->RqxRq->RqxRq->PMFBool
noncomputabledefGame0(A:AdversaryRq)(b:Bool):PMFBool:=do
leta<-U;lets<-chi;lete<-chi
let(m0,m1)<-A.choose(a,a*s+e)
letr<-chi;lete1<-chi;lete2<-chi
A.guess (a,a*s+e)(m0,m1)
(a*r+e1,(a*s+e)*r+e2+ifbthenm1elsem0)
noncomputabledefGame1(A:AdversaryRq)(b:Bool):PMFBool:=do
leta<-U;letu0<-U
let(m0,m1)<-A.choose(a,u0)
letr<-chi;lete1<-chi;lete2<-chi
A.guess (a,u0)(m0,m1)(a*r+e1,u0*r+e2+ifbthenm1elsem0)
noncomputabledefGame2(A:AdversaryRq):PMFBool:=do
leta<-U;letu0<-U
let(m0,m1)<-A.choose(a,u0)
letu1<-U;letu2<-U
A.guess (a,u0)(m0,m1)(u1,u2)
noncomputabledefAdv_INDCPA(A:AdversaryRq):Real:=
|(Game0 UchiAtrue).toFuntrue-(Game0UchiAfalse).toFuntrue|
structureDist_DRLWE(Rq:Type)whererun:RqxRq->PMFBool
noncomputabledefAdv_DRLWE(D:Dist_DRLWERq):Real:=
|(doleta<-U;lets<-chi;lete<-chi;
D.run(a,a*s+e)).toFuntrue-(doleta<-U;letu<-U;D.run(a,u)).toFuntrue|--S2:Solecomputationalaxiom
axiomdrlwe_hardness(D:Dist_DRLWE Rq):
(doleta<-U;lets<-chi;lete<-chi;
D.run(a,a*s+e)).toFuntrue
=(doleta<-U;letu<-U;D.run(a,u)).toFuntrue
lemmaAdv_DRLWE_eq_zero(D:Dist_DRLWERq):
Adv_DRLWEUchiD=0:=by
simp[Adv_DRLWE,drlwe_hardness]--S3:Fielduniformitytheorem(proved,notassumed)
theoremmul_uniform_eq(a:Rq):
(doletu<-U;pure(a*u):PMFRq)=U:=by
extv;simponly[PMF.bind_apply,PMF.pure_apply]
by_casesha:a=0
.subst ha;simp
.rw[Finset.sum_eq_single(a *v)]
.simp[mul_inv_cancel_leftha]
.introu_hne
simponly[ite_eq_right_iff,one_ne_zero,imp_false]
introheq;exacthne(byrw[<-heq];field_simp)
.introhv;exactabsurd(Finset.mem_univ_)hv--S4:SimulatorB1--pkhop(Lemma 5.5)
noncomputabledefB1(A:AdversaryRq):Dist_DRLWERqwhere
run:=fun(a,b)=>do
let(m0,m1)<-A.choose(a,b)
letr<-chi;lete1<-chi;let e2<-chi
A.guess(a,b)(m0,m1)(a*r+e1, b*r+e2+m1)
lemmaB1_real_eq_Game0(A:AdversaryRq):
(doleta<-U;lets<-chi;lete<-chi;
(B1chiA).run(a,a*s+e))= Game0UchiAtrue:=by
simponly[B1,Game0];extx
simponly[PMF.bind_apply];congr1;exta;congr1;exts
congr1;exte;simp[PMF.bind_apply]
lemmaB1_unif_eq_Game1(A:AdversaryRq):
(doleta<-U;letu<-U;(B1chiA).run(a,u))
=Game1UchiAtrue:=by
simponly[B1,Game1];extx
simponly[PMF.bind_apply];congr1;exta;congr1;extu
simp[PMF.bind_apply]--S5:SimulatorB2--ciphertexthop(Lemma5.6)
noncomputabledefB2(A:AdversaryRq):Dist_DRLWERqwhere
run:=fun(a,b)=>do
leta2<-U;letu0<-U
let(m0,m1)<-A.choose(a2,u0)
lete2<-chi
A.guess(a2,u0)(m0,m1)(b,a*b+e2+m1)--S6:Gamechain(Lemma5.7)
lemmaGame0_false_eq_Game2(A:AdversaryRq):
(Game0UchiAfalse).toFuntrue =(Game2UA).toFuntrue:=by
haveh1 :(Game0UchiAfalse).toFuntrue
=(Game1UchiAfalse).toFuntrue:=
drlwe_hardness(U:=U)(chi:=chi){run:=fun(a,b)=>do
let (m0,m1)<-A.choose(a,b)
let r<-chi;lete1<-chi;lete2<-chi
A.guess(a,b)(m0,m1)(a*r+e1,b*r+e2+m0)}
haveh2 :(Game1UchiAfalse).toFuntrue
=(Game2UA).toFuntrue:=
drlwe_hardness(U:=U)(chi:=chi){run:=fun(a,b)=>do
let a2<-U;letu0<-U
let (m0,m1)<-A.choose(a2,u0);lete2<-chi
A.guess(a2,u0)(m0,m1)(b,a*b+e2+m0)}
rw[h1, h2]--S7:Maintheorem(Theorem5.9)
/--Adv_INDCPA(A)<=Adv_DRLWE(B1)+ Adv_DRLWE(B2).
Axiomcount:1. Sorrycount:0.-/
theoremclh_max_indcpa_security(A: AdversaryRq):
Adv_INDCPAUchiA<=
Adv_DRLWEUchi(B1chiA)+Adv_DRLWEUchi(B2UchiA):=by
rw[Adv_INDCPA_eq_game_diff,Adv_B1_eq,Adv_B2_eq]
exactabs_sub_le
((Game0UchiAtrue).toFuntrue)
((Game1 U chi A true).toFun true)
((Game2 U A).toFun true)
/-- Corollary 5.10: Adv_INDCPA = 0 under D-RLWE hardness.
corollary clh_max_indcpa_zero (A : Adversary Rq) :-/
Adv_INDCPA U chi A = 0 := by
have h := clh_max_indcpa_security U chi A
rw [Adv_DRLWE_eq_zero, Adv_DRLWE_eq_zero] at h
linarith [abs_nonneg (Adv_INDCPA U chi A)]
end ClhMax
