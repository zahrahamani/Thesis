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
%   - Long markings or many places: nodes labeled S1, S2, ... (COTREE row index).
%   - Hover over a state box to see the full marking (State: ...).

    if nargin < 1
        error('plotCOTREE:MissingInput', ...
            'Usage: plotCOTREE(COTREE, [startState])');
    end
    if nargin < 2
        startState = [];
    end

    tree = iParseAndValidateCOTREE(COTREE, startState);
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
    if isempty(COTREE)
        error('plotCOTREE:EmptyCOTREE', 'COTREE must not be empty.');
    end
    if ~ismatrix(COTREE) || ~isnumeric(COTREE)
        error('plotCOTREE:InvalidCOTREEType', ...
            'COTREE must be a numeric matrix returned by cotree.');
    end
    if ~isempty(startState) && ~iscell(startState)
        error('plotCOTREE:InvalidStartState', ...
            'startState must be a cell array, e.g., {''p2'',1,''p3'',1}.');
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
    view.numPlaces = tree.numPlaces;
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
    iDrawLegend();
    iEnableStateHover(fig, ax, view);
    hold off;
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
        label = iNodeDisplayLabel(view.markings(i, :), view.stateNumbers(i), view.numPlaces);
        text(view.x(i) - length(label) * 0.0035, view.y(i), label, 'FontSize', 10);
    end
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
function label = iNodeDisplayLabel(marking, stateNum, numPlaces)
    fullLabel = iMarkingString(marking);
    if iPreferStateNumberLabel(numPlaces, fullLabel)
        label = ['S', num2str(stateNum)];
    else
        label = fullLabel;
    end
end

% -------------------------------------------------------------------------
function tf = iPreferStateNumberLabel(numPlaces, markingLabel)
    tf = numPlaces > iLargePlaceCountThreshold() ...
        || length(markingLabel) > iMaxMarkingLabelLength();
end

% -------------------------------------------------------------------------
function n = iMaxMarkingLabelLength()
    n = 30;
end

% -------------------------------------------------------------------------
function n = iLargePlaceCountThreshold()
    n = 10;
end

% -------------------------------------------------------------------------
function s = iFullMarkingTooltip(marking)
    s = ['State: ', iMarkingString(marking)];
end

% -------------------------------------------------------------------------
function iEnableStateHover(fig, ax, view)
    tipH = text(ax, NaN, NaN, '', 'Visible', 'off', ...
        'BackgroundColor', [1 1 0.93], 'Margin', 4, ...
        'EdgeColor', [0.45 0.45 0.45], 'FontSize', 9, ...
        'Clipping', 'off', 'Tag', 'plotCOTREE_hoverTip', ...
        'HitTest', 'off', 'PickableParts', 'none');

    markings = cell(numel(view.parent), 1);
    for i = 1:numel(view.parent)
        markings{i} = iFullMarkingTooltip(view.markings(i, :));
    end

    hoverData.view = view;
    hoverData.markings = markings;
    hoverData.tip = tipH;
    hoverData.ax = ax;
    setappdata(fig, 'plotCOTREE_hoverData', hoverData);
    set(fig, 'WindowButtonMotionFcn', @iOnStateHover);
end

% -------------------------------------------------------------------------
function iOnStateHover(fig, ~)
    data = getappdata(fig, 'plotCOTREE_hoverData');
    if isempty(data) || ~ishandle(data.ax) || ~ishandle(data.tip)
        return;
    end

    cp = get(data.ax, 'CurrentPoint');
    hit = iHitTestState(data.view, cp(1, 1), cp(1, 2));
    if hit > 0
        v = data.view;
        yTip = v.y(hit) + v.heights(hit) * 0.55;
        set(data.tip, 'Position', [v.x(hit), yTip, 0], ...
            'String', data.markings{hit}, 'Visible', 'on');
    else
        set(data.tip, 'Visible', 'off');
    end
end

% -------------------------------------------------------------------------
function hit = iHitTestState(view, x, y)
    hit = 0;
    for i = 1:numel(view.parent)
        inX = x >= view.x(i) - view.widths(i) / 2 ...
            && x <= view.x(i) + view.widths(i) / 2;
        inY = y >= view.y(i) - view.heights(i) / 2 ...
            && y <= view.y(i) + view.heights(i) / 2;
        if inX && inY
            hit = i;
            return;
        end
    end
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
function iDrawLegend()
    x0 = 0.74;
    y0 = 0.92;
    w = 0.035;
    h = 0.02;
    rectangle('Position', [x0, y0, w, h], 'FaceColor', [0.95 0.95 0.95]);
    text(x0 + 0.045, y0 + 0.01, 'Normal State', 'VerticalAlignment', 'middle');
    rectangle('Position', [x0, y0 - 0.04, w, h], 'FaceColor', [0.45 0.85 0.95]);
    text(x0 + 0.045, y0 - 0.03, 'Terminal State', 'VerticalAlignment', 'middle');
    rectangle('Position', [x0, y0 - 0.08, w, h], 'FaceColor', [0.45 0.95 0.45]);
    text(x0 + 0.045, y0 - 0.07, 'Duplicate State', 'VerticalAlignment', 'middle');
end
