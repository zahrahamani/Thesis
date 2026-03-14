function D = PNCT_depth(parent)
% PNCT_DEPTH  Compute the depth of each node in a tree.
%   Syntax: D = PNCT_DEPTH(PARENT)
%
%   Given the vector PARENT of parent-node indices, returns the vector D of
%   node depths, starting from the root at depth 0. The i-th element of
%   PARENT is the index of the parent of node i. Nodes are numbered
%   progressively according to their position in the tree, starting from
%   the root (at the top), from left to right and from top to bottom.
%
%   Original author: Diego Mura, 2003, University of Cagliari
%   e-mail: diegolas@inwind.it

n = length(parent);

% Add a fictitious root node #n+1 and identify the leaves.
parent = rem(parent + n, n + 1) + 1;   % change all zeros to ones
isaleaf = ones(1, n + 1);
isaleaf(parent) = zeros(n, 1);         % mark parent nodes as non-leaves

% Depth vector, initialised to 0
D = zeros(1, n);

% Traverse the tree starting from the leaves using two node pointers,
% aliga1 and aliga2, and update node depths.
for i = 1:n
    if isaleaf(i)
        aliga1 = parent(i);
        while aliga1 ~= n + 1
            aliga2 = i;
            while aliga2 ~= aliga1
                D(aliga2) = D(aliga2) + D(aliga1) + 1;
                aliga2 = parent(aliga2);
            end
            if D(aliga1) ~= 0
                break;
            end
            aliga1 = parent(aliga1);
        end
    end
end
end

