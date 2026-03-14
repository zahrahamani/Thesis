function [x, y, h] = PNCT_treelay(parent, depth)
% PNCT_TREELAY  Compute 2D layout coordinates for a tree.
%   Syntax: [x, y, h] = PNCT_TREELAY(PARENT, DEPTH)
%
%   Given the vector PARENT of parent-node indices and the vector DEPTH of
%   node depths, returns the vectors x and y containing the coordinates at
%   which to draw the nodes in order to obtain a readable graphical
%   representation of the tree. It also returns the tree height h.
%
%   Unlike the TREELAYOUT function, this layout is level-based: all nodes
%   with the same depth are placed at the same vertical position.
%
%   Original author: Diego Mura, 2003, University of Cagliari
%   e-mail: diegolas@inwind.it

% Place nodes level by level.
for lvl = 0:max(depth)           % lvl = depth level under consideration
    dummy = find(depth == lvl);  % indices of nodes at this level
    numnodes = length(dummy);    % number of nodes at this level
    k = 0;
    for i = 1:numnodes
        % Evenly space nodes at this level in the horizontal direction
        x(dummy(i)) = (2 * k + 1) / (2 * numnodes);
        k = k + 1;
    end
end

% Tree height and vertical coordinates
h = max(depth);
y = (h + 0.5 - depth) / (h + 1);
end

