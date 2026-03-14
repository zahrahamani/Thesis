function [Xb, Yb, color] = PNCT_addbox(x, y, w, h, nature)
% PNCT_ADDBOX  Compute coordinates for a set of coloured rectangles.
%   Syntax: [Xb, Yb, COLOR] = PNCT_ADDBOX(X, Y, W, H, NATURE)
%
%   Given the vectors X and Y of the coordinates where rectangles are to be
%   centred, returns the matrices Xb and Yb containing the coordinates of
%   the rectangle vertices. The rectangle sizes are defined by the vectors
%   of widths W and heights H. The integer vector NATURE determines the
%   COLOR values used to fill the rectangles according to the scheme:
%
%       NATURE(i) == -1  ..... yellow   (blocking node)
%       NATURE(i) == -2  ..... green    (normal node)
%       NATURE(i) == -3  ..... white    (legend background)
%       otherwise        ..... cyan     (duplicate node)
%
%   NOTE (1): In the special case where there are only three rectangles to
%             draw, the COLOR vector would be interpreted by PATCH as an
%             RGB triplet, making this function unusable. To avoid this,
%             an additional rectangle of zero size and white colour is
%             added at coordinates (0, 0).
%
%   NOTE (2): This function is intended to be used together with PATCH.
%             The choice of colours matches the meanings assigned in the
%             PNCT_PLOTTREE function.
%
%   NOTE (3): When PNCT_ADDBOX is executed, the figure colormap is set to
%             the default "colorcube" map. To see the available colormaps,
%             refer to the GRAPH3D help.
%
%   Original author: Diego Mura, 2003, University of Cagliari
%   e-mail: diegolas@inwind.it

% Coordinate matrices of rectangle vertices
Xb = zeros(4, length(x));
Yb = zeros(4, length(x));

% Compute rectangle vertices
for j = 1:length(x)
    Xb(1, j) = x(j) - (w(j) / 2);
    Xb(2, j) = x(j) - (w(j) / 2);
    Xb(3, j) = x(j) + (w(j) / 2);
    Xb(4, j) = x(j) + (w(j) / 2);
    Yb(1, j) = y(j) - (h(j) / 2);
    Yb(2, j) = y(j) + (h(j) / 2);
    Yb(3, j) = y(j) + (h(j) / 2);
    Yb(4, j) = y(j) - (h(j) / 2);
end

% Define colormap, brighten it and set its range
colormap(colorcube);
brighten(0.5);
caxis([1 10]);

% Assign colours to nodes
color = zeros(1, length(x)); % colour vector for the nodes
for k = 1:length(x)
    switch nature(k)
        case -1
            color(k) = 7.0;   % blocking node: yellow
        case -2
            color(k) = 9.9;   % normal node: green
        case -3
            color(k) = 9.9;   % legend background: white
        otherwise
            color(k) = 2.2;   % duplicate node: cyan
    end
end

% Handle the case of exactly three rectangles to be drawn
if length(x) == 3
    xagg = [0 0 0 0]';
    yagg = [0 0 0 0]';
    Xb = cat(2, xagg, Xb);
    Yb = cat(2, yagg, Yb);
    color = [9.9 color];
end
end

