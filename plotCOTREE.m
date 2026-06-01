function plotCOTREE(COTREE, startState)
% plotCOTREE Display reachability graph from COTREE matrix.
%
%   plotCOTREE(COTREE) displays the reachability graph starting from the
%   initial/root marking represented in COTREE.
%
%   plotCOTREE(COTREE, startState) displays the reachability graph starting
%   from the user-provided start state (marking).
%
% Inputs:
%   COTREE     - Required. Matrix returned by cotree(...).
%   startState - Optional. State definition used as root marking.
%
% Notes:
%   - COTREE matrix layout (GPenSIM / Davidrajuh Ch.4 §4.5):
%       [marking(1..P), transition_fire, parent_state, state_indicator]
%   - state_indicator: R=82 (root), T=84 (terminal), D=68 (duplicate)
%   - Display is capped (see iDefaultMaxDisplayStates).
%   - Red stubs mark nodes with hidden successors or non-initial roots.
%

    if nargin < 1
        disp('plotCOTREE: missing COTREE input; usage: plotCOTREE(COTREE, [startState]).');
        return;
    end
    if nargin < 2
        startState = [];
    end

    tree = iParseAndValidateCOTREE(COTREE, startState);
    if isempty(tree)
        return;
    end
    startIdx = iResolveStartIndex(tree, startState, nargin >= 2);
    if isempty(startIdx)
        return;
    end

    sel = iSelectSubtree(tree, startIdx, iDefaultMaxDisplayStates());
    view = iBuildPlotView(tree, sel);
    iDrawReachabilityFigure(tree, view, startIdx);
    iReportTruncation(tree.numStates, sel.count, iDefaultMaxDisplayStates());
end

% -------------------------------------------------------------------------
function n = iDefaultMaxDisplayStates()
    n = 30;
end

% -------------------------------------------------------------------------
function tree = iParseAndValidateCOTREE(COTREE, startState)
    tree = [];
    if isempty(COTREE)
        disp('plotCOTREE: COTREE is empty; no plot generated.');
        return;
    end
    if ~ismatrix(COTREE) || ~isnumeric(COTREE)
        disp('plotCOTREE: COTREE must be a numeric matrix returned by cotree; no plot generated.');
        return;
    end
    if ~isempty(startState) && ~iscell(startState)
        disp('plotCOTREE: startState must be a cell array, e.g., {''p2'',1,''p3'',1}; no plot generated.');
        return;
    end

    [numStates, numCols] = size(COTREE);
    if numCols < 4
        error('plotCOTREE:InvalidCOTREEShape', ...
            'COTREE must have at least 4 columns.');
    end

    numPlaces = numCols - 3;
    parentState = COTREE(:, numPlaces + 2);
    if any(parentState < 0) || any(parentState > numStates) || any(mod(parentState, 1) ~= 0)
        error('plotCOTREE:InvalidParentState', ...
            'parent_state column must contain integer indices in [0..N].');
    end

    tree.numStates = numStates;
    tree.numPlaces = numPlaces;
    tree.markings = COTREE(:, 1:numPlaces);
    tree.transitionFire = COTREE(:, numPlaces + 1);
    tree.parentState = parentState;
    tree.stateType = COTREE(:, numPlaces + 3);
    tree.rootIdx = iFindRootIndex(tree);
end

% -------------------------------------------------------------------------
function rootIdx = iFindRootIndex(tree)
    rootIdx = find(tree.stateType == double('R'), 1, 'first');
    if isempty(rootIdx)
        rootCandidates = find(tree.parentState == 0);
        if isempty(rootCandidates)
            error('plotCOTREE:MissingRoot', ...
                'Could not find a root state (type ''R'' or parent_state==0).');
        end
        rootIdx = rootCandidates(1);
    end
end

% -------------------------------------------------------------------------
function startIdx = iResolveStartIndex(tree, startState, useStartState)
    if ~useStartState
        startIdx = tree.rootIdx;
        return;
    end

    [startIdx, message] = iFindStateByCellMarking( ...
        tree.markings, tree.stateType, startState, tree.numPlaces);
    if isempty(startIdx)
        if isempty(message)
            disp('plotCOTREE: startState not found in COTREE; no plot generated.');
        else
            disp(message);
        end
    end
end

% -------------------------------------------------------------------------
function sel = iSelectSubtree(tree, startIdx, maxDisplayStates)
    keepMask = iBreadthFirstMask(tree.parentState, startIdx, tree.numStates, maxDisplayStates);
    selected = find(keepMask);
    if isempty(selected)
        error('plotCOTREE:EmptySelection', 'No states selected for plotting.');
    end

    sel.indices = selected;
    sel.count = numel(selected);
    sel.parent = tree.parentState(selected);
    sel.transition = tree.transitionFire(selected);
    sel.type = tree.stateType(selected);
    sel.markings = tree.markings(selected, :);
    sel.hiddenSuccessor = iHiddenSuccessorMask(tree.parentState, selected, keepMask);
end

% -------------------------------------------------------------------------
function keepMask = iBreadthFirstMask(parentState, startIdx, numStates, maxDisplayStates)
    keepMask = false(numStates, 1);
    queue = startIdx;
    keepMask(startIdx) = true;
    qHead = 1;
    addedCount = 1;

    while qHead <= numel(queue) && addedCount < maxDisplayStates
        current = queue(qHead);
        qHead = qHead + 1;
        children = find(parentState == current);
        for k = 1:numel(children)
            child = children(k);
            if ~keepMask(child)
                keepMask(child) = true;
                queue(end + 1) = child; %#ok<AGROW>
                addedCount = addedCount + 1;
                if addedCount >= maxDisplayStates
                    return;
                end
            end
        end
    end
end

% -------------------------------------------------------------------------
function hiddenSuccessor = iHiddenSuccessorMask(parentState, selected, keepMask)
    hiddenSuccessor = false(numel(selected), 1);
    for i = 1:numel(selected)
        hiddenSuccessor(i) = any((parentState == selected(i)) & ~keepMask);
    end
end

% -------------------------------------------------------------------------
function view = iBuildPlotView(tree, sel)
    mapOldToNew = zeros(tree.numStates, 1);
    mapOldToNew(sel.indices) = 1:sel.count;

    parent = sel.parent;
    for i = 1:sel.count
        if parent(i) > 0
            parent(i) = mapOldToNew(parent(i));
        end
    end

    depth = PNCT_depth(parent');
    [x, y, h] = PNCT_treelay(parent', depth);
    [widths, heights] = iNodeBoxSize(depth, h, tree.numPlaces, numel(parent));

    view.parent = parent;
    view.transition = sel.transition;
    view.type = sel.type;
    view.markings = sel.markings;
    view.hiddenSuccessor = sel.hiddenSuccessor;
    view.x = x;
    view.y = y;
    view.h = h;
    view.depth = depth;
    view.widths = widths;
    view.heights = heights;
    view.stateNumbers = sel.indices(:);
end

% -------------------------------------------------------------------------
function [widths, heights] = iNodeBoxSize(depth, treeHeight, numPlaces, numNodes)
    numnodes = 0;
    for lvl = 1:max(depth)
        numnodes = max(numnodes, sum(depth == lvl));
    end
    if numnodes == 0
        numnodes = 1;
    end
    maxWidth = min(15 * 0.012 * numPlaces, 2 / (2.8 * numnodes));
    widths = maxWidth * ones(1, numNodes);
    heights = min(0.1, 0.4 / (treeHeight + 1)) * ones(1, numNodes);
end

% -------------------------------------------------------------------------
function iDrawReachabilityFigure(tree, view, startIdx)
    fig = figure;
    clf(fig);
    hold on;
    axis([0 1 0 1]);
    ax = gca;
    ax.FontSize = 11;
    set(ax, 'XTick', [], 'YTick', []);

    iDrawEdges(view);
    iDrawNodes(view);
    iDrawRootStub(view, startIdx, tree.rootIdx);
    iDrawHiddenStubs(view);
    iDrawMarkingLabels(view);
    title(iPlaceTitle(tree.numPlaces));
    text(0.02, 0.02, ['Height = ', num2str(view.h)]);
    hold off;
    iDrawLegend(ax);
end

% -------------------------------------------------------------------------
function iDrawEdges(view)
    nonRoot = find(view.parent ~= 0);
    for k = 1:numel(nonRoot)
        child = nonRoot(k);
        parent = view.parent(child);
        plot([view.x(parent), view.x(child)], [view.y(parent), view.y(child)], 'r-');
        xt = (view.x(parent) + view.x(child)) / 2;
        yt = (view.y(parent) + view.y(child)) / 2;
        text(xt - 0.01, yt, iTransitionString(view.transition(child)), 'Color', [0.7 0 0]);
    end
end

% -------------------------------------------------------------------------
function iDrawNodes(view)
    [Xb, Yb] = iBuildBoxes(view.x, view.y, view.widths, view.heights);
    colors = iNodeColors(view.type);
    for i = 1:numel(view.parent)
        patch(Xb(:, i), Yb(:, i), colors(i, :), 'EdgeColor', [0.2 0.2 0.2]);
    end
end

% -------------------------------------------------------------------------
function iDrawRootStub(view, startIdx, rootIdx)
    if startIdx == rootIdx
        return;
    end
    dispRoot = find(view.parent == 0, 1, 'first');
    if isempty(dispRoot)
        return;
    end
    i = dispRoot;
    yTop = view.y(i) + view.heights(i) / 2;
    stubLen = max(0.02, min(0.06, 1.2 * view.heights(i)));
    plot([view.x(i), view.x(i)], [yTop + stubLen, yTop], 'r-', 'LineWidth', 1);
end

% -------------------------------------------------------------------------
function iDrawHiddenStubs(view)
    hiddenNodes = find(view.hiddenSuccessor);
    for ii = 1:numel(hiddenNodes)
        i = hiddenNodes(ii);
        yBottom = view.y(i) - view.heights(i) / 2;
        stubLen = max(0.015, min(0.05, 0.8 * view.heights(i)));
        plot([view.x(i), view.x(i)], [yBottom, yBottom - stubLen], 'r-', 'LineWidth', 1);
    end
end

% -------------------------------------------------------------------------
function iDrawMarkingLabels(view)
    for i = 1:numel(view.parent)
        label = iStateLabel(view.stateNumbers(i), view.markings(i, :));
        text(view.x(i) - length(label) * 0.0035, view.y(i), label, 'FontSize', 10);
    end
end

% -------------------------------------------------------------------------
function label = iStateLabel(stateNum, marking)
    % Supervisor-requested format: state number and marking together, e.g. "S15: 3p1 + 2p2".
    label = ['S', num2str(stateNum), ': ', iMarkingString(marking)];
end

% -------------------------------------------------------------------------
function iReportTruncation(numStates, displayedCount, maxDisplayStates)
    if displayedCount < numStates
        disp(['plotCOTREE: displaying ', num2str(displayedCount), ...
              ' of ', num2str(numStates), ' states (cap = ', num2str(maxDisplayStates), ').']);
    end
end

% -------------------------------------------------------------------------
function [stateIdx, message] = iFindStateByCellMarking(markings, stateType, startState, numPlaces)
    stateIdx = [];
    message = '';

    if mod(numel(startState), 2) ~= 0
        message = 'plotCOTREE: startState must contain place-token pairs, e.g., {''p2'',1,''p3'',1}; no plot generated.';
        return;
    end

    try
        query = cellState2vectorState(startState);
        query = query(:)';
    catch ME
        message = ['plotCOTREE: invalid startState (', ME.message, '); no plot generated.'];
        return;
    end

    if numel(query) ~= numPlaces
        message = 'plotCOTREE: startState does not match the number of places in COTREE; no plot generated.';
        return;
    end

    validMask = true(size(markings, 1), 1);
    for p = 1:numPlaces
        if isinf(query(p))
            validMask = validMask & isinf(markings(:, p));
        else
            validMask = validMask & (markings(:, p) == query(p));
        end
    end

    candidates = find(validMask);
    if isempty(candidates)
        return;
    end

    nonDuplicate = candidates(stateType(candidates) ~= double('D'));
    if ~isempty(nonDuplicate)
        stateIdx = nonDuplicate(1);
    else
        stateIdx = candidates(1);
    end
end

% -------------------------------------------------------------------------
function [Xb, Yb] = iBuildBoxes(x, y, w, h)
    Xb = zeros(4, numel(x));
    Yb = zeros(4, numel(x));
    for j = 1:numel(x)
        Xb(:, j) = [x(j) - w(j) / 2; x(j) - w(j) / 2; x(j) + w(j) / 2; x(j) + w(j) / 2];
        Yb(:, j) = [y(j) - h(j) / 2; y(j) + h(j) / 2; y(j) + h(j) / 2; y(j) - h(j) / 2];
    end
end

% -------------------------------------------------------------------------
function color = iNodeColors(typeCodes)
    color = zeros(numel(typeCodes), 3);
    for i = 1:numel(typeCodes)
        switch typeCodes(i)
            case double('R')
                color(i, :) = [0.95, 0.95, 0.95];
            case double('T')
                color(i, :) = [0.45, 0.85, 0.95];
            case double('D')
                color(i, :) = [0.45, 0.95, 0.45];
            otherwise
                color(i, :) = [0.95, 0.95, 0.95];
        end
    end
end

% -------------------------------------------------------------------------
function s = iMarkingString(m)
    s = markings_string(m);
    s = strrep(s, 'Inf', 'w');
end

% -------------------------------------------------------------------------
function s = iTransitionString(transIdx)
    if transIdx <= 0
        s = '';
        return;
    end
    s = tname(transIdx);
end

% -------------------------------------------------------------------------
function t = iPlaceTitle(numPlaces)
    names = cell(1, numPlaces);
    for i = 1:numPlaces
        names{i} = pname(i);
    end
    t = ['Places: ', strjoin(names, ', ')];
end

% -------------------------------------------------------------------------
function iDrawLegend(ax)
    % Compact translucent legend, flush to the right edge of the plot axes.
    axes(ax);
    xRight = 1.0;
    xLeft = 0.872;
    yBot = 0.878;
    yTop = 0.982;
    patch(ax, [xLeft xRight xRight xLeft], [yBot yBot yTop yTop], [1 1 1], ...
        'FaceAlpha', 0.42, 'EdgeColor', [0.55 0.55 0.55], 'LineWidth', 0.5, ...
        'HitTest', 'off', 'PickableParts', 'none', 'Clipping', 'off');

    sw = 0.016;
    sh = 0.016;
    xPad = 0.006;
    yPos = [0.958 0.928 0.898];
    colors = {[0.95 0.95 0.95], [0.45 0.85 0.95], [0.45 0.95 0.45]};
    labels = {'Normal', 'Terminal', 'Duplicate'};

    for k = 1:3
        yc = yPos(k);
        xSwR = xRight - xPad;
        xSwL = xSwR - sw;
        patch(ax, [xSwL, xSwR, xSwR, xSwL], [yc - sh / 2, yc - sh / 2, yc + sh / 2, yc + sh / 2], ...
            colors{k}, 'FaceAlpha', 0.85, 'EdgeColor', [0.35 0.35 0.35], ...
            'LineWidth', 0.5, 'HitTest', 'off', 'PickableParts', 'none', 'Clipping', 'off');
        text(ax, xSwL - 0.004, yc, labels{k}, 'FontSize', 8, ...
            'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', ...
            'Color', [0.12 0.12 0.12], 'HitTest', 'off', 'PickableParts', 'none', ...
            'Clipping', 'off');
    end
end
