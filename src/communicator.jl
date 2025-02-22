# Communicator


const NCCL_UNIQUE_ID_BYTES = 128
const ncclUniqueId_t = NTuple{NCCL_UNIQUE_ID_BYTES, Cchar}

struct UniqueID
    internal::ncclUniqueId_t

    function UniqueID()
        buf = zeros(Cchar, NCCL_UNIQUE_ID_BYTES)
        @apicall(:ncclGetUniqueId, (Ptr{Cchar},), buf)
        new(Tuple(buf))
    end
end

Base.convert(::Type{ncclUniqueId_t}, id::UniqueID) = id.internal


const ncclComm_t = Ptr{Cvoid}

struct Communicator
    handle::ncclComm_t
end

# creates a new communicator (multi thread/process version)
function Communicator(nranks, comm_id, rank)
    handle_ref = Ref{ncclComm_t}()
    @apicall(:ncclCommInitRank, (Ptr{ncclComm_t}, Cint, ncclUniqueId_t, Cint), 
             handle_ref,nranks, comm_id, rank)

    Communicator(handle_ref[])
end 

# creates a clique of communicators (single process version)
function Communicator(devices)
    ndev = length(devices)
    comms = Vector{ncclComm_t}(undef, ndev)
    devlist = Cint[dev.ordinal for dev in devices]
    @apicall(:ncclCommInitAll, (Ptr{ncclComm_t}, Cint, Ptr{Cint}), comms, ndev, devlist)
    Communicator.(comms)
end

