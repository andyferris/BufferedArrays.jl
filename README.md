# BufferedArrays

*Arrays written completely with native Julia code.*

[![Build Status](https://travis-ci.org/andyferris/BufferedArrays.jl.svg?branch=master)](https://travis-ci.org/andyferris/BufferedArrays.jl)

[![Coverage Status](https://coveralls.io/repos/andyferris/BufferedArrays.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/BufferedArrays.jl?branch=master)

[![codecov.io](http://codecov.io/github/andyferris/BufferedArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/BufferedArrays.jl?branch=master)

This package is an attempt to demonstrate how an array backed by a native Julia
memory buffer can be implemented in a performant manner. Attempts have been made
to follow similar cache-coherent storage of the array dimensions as `Base.Array`.

### Quick start

`BArray` is a subtype of `DenseArray` and therefore much of the functionality
of `Base` is inherited (including access to BLAS and LAPACK). Currently only
very simple constructors are implemented.

```julia
v = BVector{Int}(10)
m = BMatrix{Float64}(4,4)
a = BArray{Complex{Float64}}((2,2,2,2))
```
Like `Base.Array`, these constructors return arrays with unintialized storage.
However, the `BArray` cannot be resized after construction.

Future work may add support for `Generator`s in constructors and convenience
function similar to `zeros`, `ones` and `fill`.

### Discussion

The main caveats seem to be:

 * Double inderiction resulting from the fact that the `Buffer` is a `type`
   containing a pointer. Future work on the Julia compiler which would inline
   the pointer in the `Buffer` to the stack would remove the double indirection.
   (note: due the the fact that `Base.Array` is resizeable, it is the author's
   understanding that a similar double-indirection problem exists there too).

 * The garbage collector will believe the size of `BArray` is that of a pointer,
   and may not prioritize deallocation of large arrays. A method to guide the
   GC on the "real" number of bytes deallocated would be useful both here and
   for interoperability outside of Julia.

 * Performance needs to be measured carefully. At least for a subset of functions,
   performance is similar to `Base.Array`.

 * Aliasing issues have not been addressed to the extent of `Base.Array`.

 * It is assumed that the pointer in the buffer will never change - it would be
   nice if that field could be set constant.

 * **It seems to crash sometimes.** The problem relates to `free()`.
