module BufferedArrays

import Base: size, getindex, setindex!, unsafe_convert, @pure
using Base.Libc

export Buffer, ArrayOffsetBuffer, BArray, BVector, BMatrix

"""
    Buffer(bytes)

Allocate `bytes` bytes of memory, and return a `Buffer` object, which will be
garbage collected when (or after) no references to the `Buffer` remain.
"""
type Buffer
    ptr::Ptr{Void} # Ideally this would be const

    function Buffer(bytes::Int)
        out = new(malloc(bytes))
        finalizer(out, _free_buffer)
        return out
    end
end

"""
`_free_buffer(buffer)`

An internal function for freeing buffers. Users should never call this function -
it will be called automatically by the GC (and will result in errors if called
twice).
"""
_free_buffer(buf::Buffer) = free(buf.ptr)

"""
    ArrayOffsetBuffer{T,N}

A specialized buffer suitable for implementing the `BArray` type. See also `Buffer`.
"""
type ArrayOffsetBuffer{T,N}
    ptr::Ptr{Void} # Ideally this would be const

    function ArrayOffsetBuffer(bytes::Int)
        out = new(malloc(bytes+offset_bytes(T,N)) + offset_size(T,N))
        finalizer(out, _free_buffer)
        return out
    end
end

_free_buffer{T,N}(buf::ArrayOffsetBuffer{T,N}) = free(buf.ptr - offset_size(T,N))

# Calculate an offset which is in multiples of 4 Ints. This *should* result in
# good memory alignment for the first piece of data in the array (assuming
# malloc returns an well-aligned address)
# TODO do something faster w.r.t. one-based indexing
@pure function offset_size{T}(::Type{T}, N::Int)
    return offset_bytes(T,N) # - sizeof(T) # future correction for 1-based indexing
end

# The total size of the offset padding (no 1-based indexing correction, if exists)
@pure function offset_bytes{T}(::Type{T}, N::Int)
    @assert N >= 0
    tmp = N
    while tmp % 4 != 0
        tmp += 1
    end
    return sizeof(Int)*tmp
end

"""
    BArray{T}(dims)
    BArray{T}(dims...)

Constructs a N-dimensional array backed by a native Julia memory buffer, where
`dims` is an `N`-tuple of integers giving the array size and `T` is the element
type. Note: the returned array has unintialized data.
"""
immutable BArray{T,N} <: DenseArray{T,N}
    buf::ArrayOffsetBuffer{T,N}

    function BArray(sizes::NTuple{N,Int})
        bytes = sizeof(T)*prod(sizes)
        out = new(ArrayOffsetBuffer{T,N}(bytes))
        unsafe_store!(unsafe_convert(Ptr{NTuple{N,Int}}, out.buf.ptr - offset_size(T,N)), sizes)
        return out
    end
end

@inline (::Type{BA}){BA<:BArray}(x::Int...) = BA(x)
@inline (::Type{BArray{T}}){T,N}(x::NTuple{N,Int}) = BArray{T,N}(x)

Base.linearindexing{BA<:BArray}(::Union{BA,Type{BA}}) = Base.LinearFast()

size{T,N}(a::BArray{T,N}) = unsafe_load(unsafe_convert(Ptr{NTuple{N,Int}}, a.buf.ptr - offset_size(T,N)))

@inline function getindex{T,N}(a::BArray{T,N}, i::Int)
    # @boundscheck bla
    unsafe_load(unsafe_convert(Ptr{T}, a.buf.ptr), i) # oh dear! This is broken since unsafe_load assumes 1-based indexing
end

@inline function setindex!{T,N}(a::BArray{T,N}, x::T, i::Int)
    # @boundscheck bla
    unsafe_store!(unsafe_convert(Ptr{T}, a.buf.ptr), x, i)  # oh dear! This is broken since unsafe_store! assumes 1-based indexing
end

@inline unsafe_convert{T}(::Type{Ptr{T}}, a::BArray{T}) = unsafe_convert(Ptr{T}, a.buf.ptr)

"""
   BVector{T}(len)

Create a vector of length `len` and element type `T` backed by a native Julia
memory buffer. Note: the returned array has unintialized data.
"""
typealias BVector{T} BArray{T,1}

"""
   BMatrix{T}(size)
   BMatrix{T}(m, n)

Create a matrix of dimensions `size = (m,n)` and element type `T` backed by a
native Julia  memory buffer. Note: the returned array has unintialized data.
"""
typealias BMatrix{T} BArray{T,2}

end # module
