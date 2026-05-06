function plotCOTREE(COTREE, startState)
% plotCOTREE Display reachability graph from COTREE matrix.
%
%   plotCOTREE(COTREE) displays the reachability graph starting from the
%   initial marking represented in COTREE.
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
%       [marking(1..P), transition_fire, parent_state, state_type]
%   - state_type is ASCII code: R=82 (root), T=84 (terminal), D=68 (duplicate)
%   - Display is capped to the first 30 reachable states.
%   - A short downward red stub marks displayed nodes with hidden successors.

    if nargin < 1
        error('plotCOTREE:MissingInput', ...
            'COTREE is required. Usage: plotCOTREE(COTREE, startState)');
    end

    if nargin < 2
        startState = [];
    end

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
    markings = COTREE(:, 1:numPlaces);
    transitionFire = COTREE(:, numPlaces + 1);
    parentState = COTREE(:, numPlaces + 2);
    stateType = COTREE(:, numPlaces + 3);

    if any(parentState < 0) || any(parentState > numStates) || any(mod(parentState, 1) ~= 0)
        error('plotCOTREE:InvalidParentState', ...
            'parent_state column must contain integer indices in [0..N].');
    end

    rootIdx = find(stateType == double('R'), 1, 'first');
    if isempty(rootIdx)
        rootCandidates = find(parentState == 0);
        if isempty(rootCandidates)
            error('plotCOTREE:MissingRoot', ...
                'Could not find a root state (type ''R'' or parent_state==0).');
        end
        rootIdx = rootCandidates(1);
    end

    if isempty(startState)
        startIdx = rootIdx;
    else
        startIdx = iFindStateByCellMarking(markings, startState, numPlaces);
    end

    maxDisplayStates = 30;
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
                    break;
                end
            end
        end
    end

    selected = find(keepMask);
    if isempty(selected)
        error('plotCOTREE:EmptySelection', 'No states selected for plotting.');
    end

    selectedParent = parentState(selected);
    selectedTransition = transitionFire(selected);
    selectedType = stateType(selected);
    selectedMarkings = markings(selected, :);
    hiddenSuccessor = false(numel(selected), 1);
    for i = 1:numel(selected)
        hiddenSuccessor(i) = any((parentState == selected(i)) & ~keepMask);
    end

    mapOldToNew = zeros(numStates, 1);
    mapOldToNew(selected) = 1:numel(selected);
    for i = 1:numel(selectedParent)
        if selectedParent(i) > 0
            selectedParent(i) = mapOldToNew(selectedParent(i));
        end
    end

    depth = PNCT_depth(selectedParent');
    [x, y, h] = PNCT_treelay(selectedParent', depth);

    figure;
    clf;
    hold on;
    axis([0 1 0 1]);
    ax = gca;
    ax.FontSize = 11;
    set(ax, 'XTick', [], 'YTick', []);

    nonRoot = find(selectedParent ~= 0);
    for k = 1:numel(nonRoot)
        child = nonRoot(k);
        parent = selectedParent(child);
        plot([x(parent), x(child)], [y(parent), y(child)], 'r-');
        xt = (x(parent) + x(child)) / 2;
        yt = (y(parent) + y(child)) / 2;
        text(xt - 0.01, yt, sprintf('t%d', selectedTransition(child)), 'Color', [0.7 0 0]);
    end

    numnodes = 0;
    for lvl = 1:max(depth)
        numnodes = max(numnodes, sum(depth == lvl));
    end
    if numnodes == 0
        numnodes = 1;
    end
    maxWidth = min(15 * 0.012 * numPlaces, 2 / (2.8 * numnodes));
    widths = maxWidth * ones(1, numel(selectedParent));
    heights = min(0.1, 0.4 / (h + 1)) * ones(1, numel(selectedParent));

    [Xb, Yb] = iBuildBoxes(x, y, widths, heights);
    nodeColors = iNodeColors(selectedType);
    for i = 1:numel(selectedParent)
        patch(Xb(:, i), Yb(:, i), nodeColors(i, :), 'EdgeColor', [0.2 0.2 0.2]);
    end

    if startIdx ~= rootIdx
        dispRoot = find(selectedParent == 0, 1, 'first');
        if ~isempty(dispRoot)
            yTop = y(dispRoot) + heights(dispRoot) / 2;
            stubLen = max(0.02, min(0.06, 1.2 * heights(dispRoot)));
            plot([x(dispRoot), x(dispRoot)], [yTop + stubLen, yTop], ...
                'r-', 'LineWidth', 1);
        end
    end

    hiddenNodes = find(hiddenSuccessor);
    for ii = 1:numel(hiddenNodes)
        i = hiddenNodes(ii);
        yBottom = y(i) - heights(i) / 2;
        stubLen = max(0.015, min(0.05, 0.8 * heights(i)));
        plot([x(i), x(i)], [yBottom, yBottom - stubLen], 'r-', 'LineWidth', 1);
    end

    for i = 1:numel(selectedParent)
        label = iMarkingString(selectedMarkings(i, :), numPlaces);
        text(x(i) - length(label) * 0.0035, y(i), label, 'FontSize', 10);
    end

    title(iPlaceTitle(numPlaces));
    text(0.02, 0.02, ['Height = ', num2str(h)]);
    iDrawLegend();
    hold off;

    if numel(selected) < sum(keepMask) || sum(keepMask) < numStates
        disp(['plotCOTREE: displaying ', num2str(numel(selected)), ...
              ' of ', num2str(numStates), ' states (cap = ', num2str(maxDisplayStates), ').']);
    end
end

function stateIdx = iFindStateByCellMarking(markings, startState, numPlaces)
    if mod(numel(startState), 2) ~= 0
        error('plotCOTREE:InvalidStartState', ...
            'startState must contain place-token pairs, e.g., {''p2'',1,''p3'',1}.');
    end

    query = nan(1, numPlaces);
    for ii = 1:2:numel(startState)
        placeName = startState{ii};
        tokenCount = startState{ii + 1};
        if ~ischar(placeName) && ~isstring(placeName)
            error('plotCOTREE:InvalidStartStatePlace', ...
                'Place names in startState must be strings, e.g., ''p2''.');
        end
        placeName = char(placeName);
        tok = regexp(placeName, '^p(\d+)$', 'tokens', 'once');
        if isempty(tok)
            error('plotCOTREE:InvalidStartStatePlace', ...
                'Unsupported place name "%s". Expected p1, p2, ...', placeName);
        end
        placeIdx = str2double(tok{1});
        if placeIdx < 1 || placeIdx > numPlaces
            error('plotCOTREE:StartStatePlaceOutOfRange', ...
                'Place index in "%s" is out of range for this COTREE.', placeName);
        end
        query(placeIdx) = tokenCount;
    end

    validMask = true(size(markings, 1), 1);
    for p = 1:numPlaces
        if ~isnan(query(p))
            validMask = validMask & (markings(:, p) == query(p));
        end
    end
    candidates = find(validMask);
    if isempty(candidates)
        error('plotCOTREE:StartStateNotFound', ...
            'Provided startState does not match any marking in COTREE.');
    end
    stateIdx = candidates(1);
end

function label = iTypeLabel(typeCode)
    switch typeCode
        case double('R')
            label = 'R';
        case double('T')
            label = 'T';
        case double('D')
            label = 'D';
        otherwise
            label = '-';
    end
end

function [Xb, Yb] = iBuildBoxes(x, y, w, h)
    Xb = zeros(4, numel(x));
    Yb = zeros(4, numel(x));
    for j = 1:numel(x)
        Xb(:, j) = [x(j) - w(j) / 2; x(j) - w(j) / 2; x(j) + w(j) / 2; x(j) + w(j) / 2];
        Yb(:, j) = [y(j) - h(j) / 2; y(j) + h(j) / 2; y(j) + h(j) / 2; y(j) - h(j) / 2];
    end
end

function color = iNodeColors(typeCodes)
    color = zeros(numel(typeCodes), 3);
    for i = 1:numel(typeCodes)
        switch typeCodes(i)
            case double('R')
                color(i, :) = [0.95, 0.95, 0.95]; % root: light gray
            case double('T')
                color(i, :) = [0.45, 0.85, 0.95]; % terminal: cyan
            case double('D')
                color(i, :) = [0.45, 0.95, 0.45]; % duplicate: green
            otherwise
                color(i, :) = [0.95, 0.95, 0.95]; % normal: light gray
        end
    end
end

function s = iMarkingString(m, numPlaces)
    parts = {};
    for p = 1:numPlaces
        val = m(p);
        if val > 0
            if isinf(val)
                parts{end + 1} = sprintf('wp%d', p); %#ok<AGROW>
            elseif val == 1
                parts{end + 1} = sprintf('p%d', p); %#ok<AGROW>
            else
                parts{end + 1} = sprintf('%g p%d', val, p); %#ok<AGROW>
            end
        end
    end
    if isempty(parts)
        s = '0';
    else
        s = strjoin(parts, ' + ');
    end
end

function t = iPlaceTitle(numPlaces)
    names = arrayfun(@(i) sprintf('p%d', i), 1:numPlaces, 'UniformOutput', false);
    t = ['Places: ', strjoin(names, ', ')];
end

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
