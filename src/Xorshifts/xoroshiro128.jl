import Base: copy, copyto!, ==
import Random: rand, srand
import RandomNumbers: AbstractRNG, gen_seed, split_uint, seed_type

"""
```julia
AbstractXoroshiro128 <: AbstractRNG{UInt64}
```

The base abstract type for `Xoroshiro128`, `Xoroshiro128Star` and `Xoroshiro128Plus`.
"""
abstract type AbstractXoroshiro128 <: AbstractRNG{UInt64} end

@inline xorshift_rotl(x::UInt64, k) = (x << k) | (x >> (64 - k))

for (star, plus) in (
        (false, false),
        (false, true),
        (true, false),
    )
    rng_name = Symbol(string("Xoroshiro128", star ? "Star" : plus ? "Plus" : ""))
    @eval begin
        mutable struct $rng_name <: AbstractXoroshiro128
            x::UInt64
            y::UInt64
            function $rng_name(seed::NTuple{2, UInt64}=gen_seed(UInt64, 2))
                r = new(0, 0)
                srand(r, seed)
                r
            end
        end

        $rng_name(seed::Integer) = $rng_name(split_uint(seed % UInt128))

        @inline function xorshift_next(r::$rng_name)
            $(plus ? :(p = r.x + r.y) : nothing)
            s1 = r.y ⊻ r.x
            r.x = xorshift_rotl(r.x, 55) ⊻ s1 ⊻ (s1 << 14)
            r.y = xorshift_rotl(s1, 36)
            $(star ? :(r.y * 2685821657736338717) :
              plus ? :(p) : :(r.y))
        end
    end
end

@inline seed_type(::Type{T}) where T <: AbstractXoroshiro128 = NTuple{2, UInt64}

function copyto!(dest::T, src::T) where T <: AbstractXoroshiro128
    dest.x = src.x
    dest.y = src.y
    dest
end

copy(src::T) where T <: AbstractXoroshiro128 = copyto!(T(), src)

==(r1::T, r2::T) where T <: AbstractXoroshiro128 = r1.x == r2.x && r1.y == r2.y

srand(r::AbstractXoroshiro128, seed::Integer) = srand(r, split_uint(seed % UInt128))
function srand(r::AbstractXoroshiro128, seed::NTuple{2, UInt64}=gen_seed(UInt64, 2))
    r.x = seed[1]
    r.y = seed[2]
    xorshift_next(r)
    xorshift_next(r)
    r
end

@inline rand(r::AbstractXoroshiro128, ::Type{UInt64}) = xorshift_next(r)
