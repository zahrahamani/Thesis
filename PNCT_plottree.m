function [] = PNCT_plottree(T)
% PNCT_PLOTTREE  Plot a reachability / coverability tree for a Petri net.
%   Syntax:
%       PNCT_PLOTTREE(T)
%
%   Draws the complete reachability / coverability tree represented by the
%   matrix T, obtained for example with T = TREE(Pre, Post, M0).
%   This version differs from PLOTTREE1 because it does not use self-loops.
%
%   NOTE:
%       For trees with many nodes at the same depth, the markings may
%       extend outside the node boxes. In that case, left-click on the
%       figure area to zoom in and read the marking more easily; a
%       right-click returns to the normal representation (the ZOOM
%       feature is active). In some cases, enlarging the figure window
%       is also helpful.
%
%   Based on the TREEPLOT function
%       (Copyright (c) 1984–97 by The MathWorks, Inc.
%        $Revision: 5.7 $  $Date: 1997/04/08 06:40:28 $).
%
%   WARNING:
%       This function calls the helper functions PNCT_ADDBOX,
%       PNCT_TREELAY and PNCT_DEPTH. If these are modified or not present
%       in the same folder as PNCT_PLOTTREE, the program will not work
%       correctly.
%
%   See also:
%       PNCT_TREELAY, TREE, PNCT_DEPTH, PNCT_ADDBOX, PLOTTREE1.
%
%   Original author: Diego Mura, 2003, University of Cagliari
%   e-mail: diegolas@inwind.it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Gentle touch of GPenSIM here   :-)
global PN
Ps = PN.No_of_places;
%%%%%% GPenSIM ends %%%%%%%%%%%%%%%% 

clf;

[m, n] = size(T);

% Extract nature of nodes from column (m+2), excluding the last row
nature = T(1:m-1, T(m,1)+2)';

% Extract parent-node indices from column (m+1), excluding the last row
p = T(1:m-1, T(m,1)+1)';

% Compute depth of each node
d = PNCT_depth(p);

% Compute coordinates of the tree nodes
[x, y, h] = PNCT_treelay(p, d);

% Indices of non-root nodes and their parents
f  = find(p ~= 0);     % non-root nodes
pp = p(f);             % parents of non-root nodes

% Build coordinates of line segments for edges
X = [x(f);  x(pp);  repmat(NaN, size(f))];
Y = [y(f);  y(pp);  repmat(NaN, size(f))];

% Stack everything into column vectors
X = X(:);
Y = Y(:);

l = length(p);

% Draw the edges
plot(X, Y, 'r-');

% Set font size = 12
ax = gca;
ax.FontSize = 12;

xlabel(['Height = ' int2str(h)]);
axis([0 1 0 1]);

% Compute the maximum number of nodes at any tree level
numnodes = 0;
for k = 1:max(d)
    dummy    = find(d == k);
    v        = length(dummy);
    numnodes = max(numnodes, v);
end

% Add coloured rectangles to the plot

% Avoid division by zero when the tree has only the root node
if numnodes == 0
    numnodes = 1;
end

% 0.012 is the estimated width of one character
maxlargh = min(15 * 0.012 * T(m,1), 2 / (2.8 * numnodes));
largh    = maxlargh * ones(1, length(p)); % rectangle widths

maxalt = min(0.1, 0.4 / (h + 1));
alt    = maxalt * ones(1, length(p));     % rectangle heights

[Xb, Yb, color] = PNCT_addbox(x, y, largh, alt, nature);
patch(Xb, Yb, color);

% Define font family and size for node labels
if numnodes <= 7
    s         = 9;
    carattere = 'arial';
else
    s         = 7;
    carattere = 'verdana';
end

if numnodes < 10
    parametro = 1;
else
    parametro = 0.5;
end

% Insert markings inside the rectangles
for i = 1:length(p)
    marcatura = T(i, 1:T(m,1));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % Gentle touch of GPenSIM here   :-)
    % to convert token markings into a string for display
    % OLD code:   etichetta = dec2str(marcatura);
    etichetta = markings_string(marcatura);
    %%%% GPenSIM ends %%%%%%%%%%%%%%%%%%% 

    % Replace all 'Inf' strings with 'w'
    etichetta = strrep(etichetta, 'Inf', 'w');

    % Center the text horizontally in the rectangle
    text(x(i) - length(etichetta) * 0.004 * parametro, ...
         y(i), etichetta, 'fontsize', s, 'fontname', carattere);
end

% Place transition labels slightly to the left of the edge midpoints
for ii = 1:length(p)
    % Pointer to the column of nodes reached by the current transition
    jj = T(m,1) + 4;
    % Pointer to the column of transitions
    tt = T(m,1) + 3;

    while (tt < n) && (T(ii,tt) ~= 0)
        if abs(x(ii) - x(T(ii,jj))) < 0.03
            xt = (x(ii) + x(T(ii,jj))) / 2 - parametro * 0.025;
        else
            xt = (x(ii) + x(T(ii,jj))) / 2 - parametro * 0.04;
        end
        yt   = (y(ii) + y(T(ii,jj))) / 2;
        tran = T(ii,tt);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % Gentle touch of GPenSIM here   :-)
        % OLD: transizione = strcat('t', transizione);
        transizione = PN.global_transitions(tran).name;
        %%% GPenSIM ends %%%%%%%%%%%%%%%%%%%
        text(xt, yt, transizione);

        tt = tt + 2;
        jj = jj + 2;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gentle touch of GPenSIM here   :-)
% OLD: title('Coverability / Reachability Tree'); 
Place_names = '';
for i = 1:Ps
    Place_names = [Place_names, ' ', PN.global_places(i).name, ','];
end
Place_names = Place_names(1:end-1); % remove trailing ','
Place_names = ['Places: ', Place_names];
title(Place_names);
%%% GPenSIM ends %%%%%%%%%%%%%%%%%%%

% Create the legend
xlegenda     = [0.85 0.745 0.745 0.745];
ylegenda     = [0.925 0.965 0.925 0.885];
colorlegenda = [-3 -2 -1 0];
xdim         = [0.28 0.05 0.05 0.05];
ydim         = [0.13 0.03 0.03 0.03];

[Xleg, Yleg, colorleg] = PNCT_addbox(xlegenda, ylegenda, xdim, ydim, colorlegenda);
patch(Xleg, Yleg, colorleg);

text(0.79, 0.965, 'Normal State');
text(0.79, 0.925, 'Terminal State');
text(0.79, 0.885, 'Duplicate State');

% Remove tick labels and tick marks from axes
set(gca, 'XTicklabel', [''], 'YTicklabel', [''], 'XTick', [], 'YTick', []);

zoom on;   % activate the ZOOM function
return

% Note:
%   Helper functions PNCT_DEPTH, PNCT_TREELAY and PNCT_ADDBOX are defined
%   in their own files (PNCT_depth.m, PNCT_treelay.m, PNCT_addbox.m) to
%   keep PNCT_plottree.m shorter and easier to read.