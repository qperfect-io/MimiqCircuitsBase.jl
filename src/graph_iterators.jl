#
# Copyright © 2026 QPerfect. All Rights Reserved.
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

"""
    DepthFirstIterator

Iterator that traverses the AbstractCircuit in a depth-first topological order.
"""
struct DepthFirstIterator
    graph::AbstractCircuit
    order::Vector{Int}
end

function DepthFirstIterator(c::AbstractCircuit)
    _ensure_cache!(c)
    order = topological_sort_by_dfs(graph(c))
    return DepthFirstIterator(c, order)
end

Base.iterate(iter::DepthFirstIterator, state=1) = state > length(iter.order) ? nothing : (iter.graph._instructions[iter.order[state]], state + 1)
Base.length(iter::DepthFirstIterator) = length(iter.order)
Base.eltype(::DepthFirstIterator) = Instruction

"""
    topological_sort_by_bfs(g::AbstractGraph)

Perform a topological sort of the graph using a breadth-first search (Kahn's algorithm).
Returns a vector of vertices in topological order.
"""
function topological_sort_by_bfs(g::AbstractGraph)
    n = nv(g)
    in_degree = [indegree(g, v) for v in 1:n]
    queue = Int[]

    # Enqueue 0-in-degree nodes (keeping them sorted for determinism)
    start_nodes = findall(==(0), in_degree)
    append!(queue, start_nodes)

    order = Int[]
    sizehint!(order, n)

    idx = 1
    while idx <= length(queue)
        u = queue[idx]
        idx += 1
        push!(order, u)

        for v in outneighbors(g, u)
            in_degree[v] -= 1
            if in_degree[v] == 0
                push!(queue, v)
            end
        end
    end

    return order
end

"""
    BreadthFirstIterator

Iterator that traverses the AbstractCircuit in a breadth-first topological order (layer by layer).
This uses Kahn's algorithm with a FIFO queue.
"""
struct BreadthFirstIterator
    graph::AbstractCircuit
    order::Vector{Int}
end

function BreadthFirstIterator(c::AbstractCircuit)
    _ensure_cache!(c)
    order = topological_sort_by_bfs(graph(c))
    return BreadthFirstIterator(c, order)
end

Base.iterate(iter::BreadthFirstIterator, state=1) = state > length(iter.order) ? nothing : (iter.graph._instructions[iter.order[state]], state + 1)
Base.length(iter::BreadthFirstIterator) = length(iter.order)
Base.eltype(::BreadthFirstIterator) = Instruction

"""
    traverse_by_dfs(graph::AbstractCircuit)

Return an iterator that traverses the circuit in a depth-first topological order.
"""
traverse_by_dfs(c::AbstractCircuit) = DepthFirstIterator(c)

"""
    traverse_by_bfs(c::AbstractCircuit)

Return an iterator that traverses the circuit in a breadth-first topological order.
"""
traverse_by_bfs(c::AbstractCircuit) = BreadthFirstIterator(c)