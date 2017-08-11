#Base.one(::Type{V}) where {V <: Variable} = Monomial{(V(),), 1}()
#Base.one(::Type{M}) where {M <: Monomial} = M()
#Base.one(m::MonomialLike) = one(typeof(m))
#Base.one(::Type{Term{T, M}}) where {T, M} = Term(one(T), M())
#Base.one(t::Term) = one(typeof(t))
Base.one(::Type{P}) where {C, T, P <: Polynomial{C, T}} = Polynomial(one(T))
Base.one(p::Polynomial) = one(typeof(p))

#Base.zero(::Type{V}) where {V <: Variable} = Polynomial([Term(0, Monomial(V()))])
#Base.zero(::Type{M}) where {M <: Monomial} = Polynomial([Term(0, M())])
#Base.zero(::Type{Term{T, M}}) where {T, M} = Polynomial([Term{T, M}(zero(T), M())])
Base.zero(::Type{Polynomial{C, T, A}}) where {C, T, A} = zero(T)
Base.zero(t::PolynomialLike) = zero(typeof(t))

combine(t1::Term, t2::Term) = combine(promote(t1, t2)...)
combine(t1::T, t2::T) where {T <: Term} = Term(t1.coefficient + t2.coefficient, t1.monomial)
compare(t1::Term, t2::Term) = monomial(t1) > monomial(t2)

jointerms(terms1::AbstractArray{<:Term}, terms2::AbstractArray{<:Term}) = mergesorted(terms1, terms2, compare, combine)

# Multiplication is handled as a special case so that we can write these
# definitions without resorting to promotion:
MP.multconstant(α, v::MonomialLike) = Term(α, Monomial(v))
MP.multconstant(v::MonomialLike, α) = Term(α, Monomial(v))

#for T1 in [Variable, Monomial, Term, Polynomial]
#    for T2 in [Variable, Monomial, Term, Polynomial]
#        if T1 != T2
#            @eval (*)(x1::$T1, x2::$T2) = (*)(promote(x1, x2)...)
#        end
#    end
#end

(*)(v1::V, v2::V) where {V <: Variable} = Monomial{(V(),), 1}((2,))
(*)(v1::Variable, v2::Variable) = (*)(promote(v1, v2)...)

function MP.divides(m1::Monomial{V, N}, m2::Monomial{V, N}) where {V, N}
    reduce((d, exp) -> d && (exp[1] <= exp[2]), true, zip(m1.exponents, m2.exponents))
end
MP.divides(m1::Monomial, m2::Monomial) = divides(promote(m1, m2)...)
function combinemono(m1::Monomial{V, N}, m2::Monomial{V, N}, op) where {V, N}
    e1 = m1.exponents
    e2 = m2.exponents
    Monomial{V, N}(ntuple(i -> op(e1[i], e2[i]), Val{N}))
end
combinemono(m1::Monomial, m2::Monomial, op) = combinemono(promote(m1, m2)..., op)
# _div(a, b) assumes that b divides a
MP._div(m1::Monomial, m2::Monomial) = combinemono(m1, m2, -)
(*)(m1::Monomial, m2::Monomial) = combinemono(m1, m2, +)

(*)(t1::Term, t2::Term) = Term(coefficient(t1) * coefficient(t2), monomial(t1) * monomial(t2))
(*)(p1::P1, p2::P2) where {P1 <: Polynomial, P2 <: Polynomial} = (*)(promote(p1, p2)...)

# TODO: this could be faster with an in-place summation
function (*)(p1::P, p2::P) where {P <: Polynomial}
    C = coefftype(termtype(P))
    M = monomialtype(termtype(P))
    result = Polynomial([Term(zero(C), M())])
    for t1 in terms(p1)
        for t2 in terms(p2)
            result += t1 * t2
        end
    end
    result
end

MP.multconstant(x, t::Term) = Term(x * coefficient(t), monomial(t))
MP.multconstant(t::Term, x) = Term(coefficient(t) * x, monomial(t))
MP.multconstant(p::Polynomial, x) = (*)(promote(p, x)...)
MP.multconstant(x, p::Polynomial) = (*)(promote(x, p)...)

^(v::V, x::Integer) where {V <: Variable} = Monomial{(V(),), 1}((x,))

# All of these types are immutable, so there's no need to copy anything to get
# a shallow copy.
Base.copy(x::PolynomialLike) = x
