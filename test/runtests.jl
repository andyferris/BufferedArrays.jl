using BufferedArrays
using Base.Test

bv = BVector{Int}(10)
@test size(bv) == (10,)
b = [i for i = 1:10]
bv .= b
@test bv == b
