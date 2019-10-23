module DummyPool

# dummy allocator that passes through any requests, calling into the GC if that fails.

using ..CuArrays: @pool_timeit, actual_alloc, actual_free

using CUDAdrv

init() = return

deinit() = @assert isempty(allocated) "Cannot deinitialize memory pool with outstanding allocations"

const allocated = Dict{CuPtr{Nothing},Int}()

function alloc(sz)
    ptr = nothing
    for phase in 1:3
        if phase == 2
            @pool_timeit "$phase.0 gc(false)" GC.gc(false)
        elseif phase == 3
            @pool_timeit "$phase.0 gc(true)" GC.gc(true)
        end

        @pool_timeit "$phase.1 alloc" begin
            ptr = actual_alloc(sz)
        end
        ptr === nothing || break
    end

    if ptr !== nothing
        allocated[ptr] = sz
        return ptr
    else
        return nothing
    end
end

function free(ptr)
    sz = allocated[ptr]
    delete!(allocated, ptr)
    actual_free(ptr)
    return
end

used_memory() = isempty(allocated) ? 0 : sum(sizeof, values(allocated))

cached_memory() = 0

dump() = return

end
