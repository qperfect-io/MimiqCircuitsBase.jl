#
# Copyright © 2022-2023 University of Strasbourg. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function ctrl(m::Matrix{T})::Matrix{T} where {T}
    id = typeof(m)(I, size(m)...)
    cat(id, m, dims=(1, 2))
end

function ctrl2(m::Matrix{T})::Matrix{T} where {T}

    return [1.0 0.0 0.0 0.0
        0.0 m[1, 1] 0.0 m[1, 2]
        0.0 0.0 1.0 0.0
        0.0 m[2, 1] 0.0 m[2, 2]]
end

function ctrlfs(m::Matrix{T})::Matrix{T} where {T}

    return ctrl(m) * ctrl2(m)
end

function ctrlsf(m::Matrix{T})::Matrix{T} where {T}

    return ctrl2(m) * ctrl(m)
end


function _decomplex(m::Matrix{T}) where {T<:Complex}
    if all(isreal, m)
        return real.(m)
    end
    return m
end

_decomplex(m::Matrix{T}) where {T<:Real} = m

function _decomplex(x::Complex)
    if isreal(x)
        return real(float(x))
    end
    return float(x)
end

function _decomplex(x::Real)
    return float(x)
end

function _shortenfloat(x::AbstractFloat; sigdigits::Integer=4)
    xs = trunc(x, sigdigits=sigdigits)

    if xs != x
        return "$(xs)..."
    end

    return string(x)
end

function _shortenfloat_pi(x::AbstractFloat; kwargs...)
    s = sign(x)
    pipart = s >= 0 ? "π⋅" : "-π⋅"
    pipart * _shortenfloat(abs(x) / π; kwargs...)
end
