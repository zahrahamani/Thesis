function GCT_viewer(T)
% GCT_VIEWER  Prototype coverability tree viewer with moving window.
%   Syntax:
%       GCT_VIEWER(T)
%
%   Displays:
%     - Figure 1: full tree (legacy display).
%     - Figure 2: tree in a depth range [startDepth .. endDepth], controlled
%       by two sliders: start depth and window size.
%     - A simple state search ("Go to state") that moves the window to
%       include that state and highlights it.
%
%   Input:
%       T  - coverability / reachability tree matrix.

    % Figure 1: full tree
    figure(1);
    clf;
    PNCT_plottree(T);

    % Precompute depth information for windowing.
    [m, n] = size(T);
    numPlaces = T(m, 1);
    parentCol = numPlaces + 1;
    parent = T(1:m-1, parentCol)';
    depth = PNCT_depth(parent);
    maxDepthAvailable = max(depth);
    oldNodeCount = m - 1;
    selectedState = [];
    visibleStates = [];
    isUpdatingPopup = false;

    if isempty(maxDepthAvailable)
        return;
    end

    % Figure 2: interactive windowed tree
    fig2 = figure(2);
    clf(fig2);
    ax = axes('Parent', fig2, 'Position', [0.05 0.20 0.90 0.75]);

    % Start depth slider
    startSlider = uicontrol(fig2, 'Style', 'slider', ...
        'Units', 'normalized', ...
        'Position', [0.22 0.08 0.56 0.04], ...
        'Min', 0, 'Max', maxDepthAvailable, ...
        'Value', 0);
    startSlider.SliderStep = [1/max(1, maxDepthAvailable) 1/max(1, maxDepthAvailable)];

    % Window size slider (minimum size 1 level)
    sizeSlider = uicontrol(fig2, 'Style', 'slider', ...
        'Units', 'normalized', ...
        'Position', [0.22 0.03 0.56 0.04], ...
        'Min', 0, 'Max', maxDepthAvailable, ...
        'Value', min(2, maxDepthAvailable));
    sizeSlider.SliderStep = [1/max(1, maxDepthAvailable) 1/max(1, maxDepthAvailable)];

    % Labels and value boxes
    uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.08 0.18 0.04], ...
        'String', 'Start depth:');

    startValueText = uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.80 0.08 0.18 0.04], ...
        'String', '');

    uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.03 0.18 0.04], ...
        'String', 'Window size:');

    sizeValueText = uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.80 0.03 0.18 0.04], ...
        'String', '');

    % Visible state selector + clear button
    uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'Position', [0.02 0.14 0.18 0.04], ...
        'String', 'Visible states:');

    visibleStatesPopup = uicontrol(fig2, 'Style', 'popupmenu', ...
        'Units', 'normalized', ...
        'Position', [0.22 0.14 0.20 0.04], ...
        'String', {'(none)'}, ...
        'Value', 1, ...
        'Callback', @(~,~) onSelectVisibleState());

    uicontrol(fig2, 'Style', 'pushbutton', ...
        'Units', 'normalized', ...
        'Position', [0.44 0.14 0.10 0.04], ...
        'String', 'Clear', ...
        'Callback', @(~,~) onClearState());

    statusText = uicontrol(fig2, 'Style', 'text', ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'left', ...
        'Position', [0.56 0.14 0.42 0.04], ...
        'String', '');

    renderWindow();
    startSlider.Callback = @(~,~) renderWindow();
    sizeSlider.Callback = @(~,~) renderWindow();

    function onSelectVisibleState()
        if isUpdatingPopup
            return;
        end
        if isempty(visibleStates)
            selectedState = [];
            statusText.String = '';
            renderWindow();
            return;
        end
        idx = visibleStatesPopup.Value;
        if idx < 1 || idx > numel(visibleStates)
            selectedState = [];
            statusText.String = '';
            renderWindow();
            return;
        end
        selectedState = visibleStates(idx);
        statusText.String = sprintf('Highlighted state %d.', selectedState);
        renderWindow();
    end

    function onClearState()
        selectedState = [];
        statusText.String = '';
        renderWindow();
    end

    function renderWindow()
        startDepth = round(startSlider.Value);
        winSize = max(1, round(sizeSlider.Value));
        endDepth = min(maxDepthAvailable, startDepth + winSize);

        % Clamp start so [startDepth..endDepth] is valid.
        if startDepth > endDepth
            startDepth = endDepth;
        end

        startSlider.Value = startDepth;
        sizeSlider.Value = winSize;
        startValueText.String = num2str(startDepth);
        sizeValueText.String = num2str(winSize);

        keepIdx = find(depth >= startDepth & depth <= endDepth);
        if isempty(keepIdx)
            cla(ax);
            title(ax, sprintf('Windowed view (depth %d..%d)', startDepth, endDepth));
            isUpdatingPopup = true;
            visibleStates = [];
            visibleStatesPopup.String = {'(none)'};
            visibleStatesPopup.Value = 1;
            selectedState = [];
            statusText.String = '';
            isUpdatingPopup = false;
            return;
        end

        Tw = buildWindowTree(T, keepIdx, n, numPlaces);
        oldToNew = zeros(1, oldNodeCount);
        oldToNew(keepIdx) = 1:numel(keepIdx);

        % Update visible-state popup for this window.
        visibleStates = keepIdx(:)';
        if ~isempty(visibleStates)
            strs = arrayfun(@(x) num2str(x), visibleStates, 'UniformOutput', false);
            isUpdatingPopup = true;
            visibleStatesPopup.String = strs;
            if isempty(selectedState)
                visibleStatesPopup.Value = 1;
            else
                % Robustness: ensure selectedState is a scalar.
                if ~isscalar(selectedState)
                    selectedState = selectedState(1);
                end

                idxSel = find(visibleStates == selectedState, 1);
                if isempty(idxSel)
                    % Keep selection only if it is visible.
                    selectedState = [];
                    statusText.String = '';
                    visibleStatesPopup.Value = 1;
                else
                    visibleStatesPopup.Value = idxSel;
                end
            end
            isUpdatingPopup = false;
        else
            isUpdatingPopup = true;
            visibleStatesPopup.String = {'(none)'};
            visibleStatesPopup.Value = 1;
            selectedState = [];
            statusText.String = '';
            isUpdatingPopup = false;
        end

        % If a state is selected and visible in this window, recolor it
        % as highlighted (green by using nature = -2).
        if ~isempty(selectedState) && selectedState >= 1 && selectedState <= oldNodeCount
            if oldToNew(selectedState) > 0
                natureCol = numPlaces + 2;
                Tw(oldToNew(selectedState), natureCol) = -2;
                statusText.String = sprintf('Highlighted state %d.', selectedState);
            else
                statusText.String = sprintf('State %d outside current window.', selectedState);
            end
        end

        PNCT_plottree(Tw, ax);

        focusSuffix = '';
        if ~isempty(selectedState)
            focusSuffix = sprintf(' | Focus state: %d', selectedState);
        end
        title(ax, sprintf('Windowed view (depth %d..%d)%s', startDepth, endDepth, focusSuffix));
    end
end

function Tw = buildWindowTree(T, keepIdx, n, numPlaces)
% Build a clean reduced tree using only kept nodes and remapped indices.
    parentCol = numPlaces + 1;
    transColStart = numPlaces + 3;
    nodeColStart = numPlaces + 4;

    oldNodeCount = size(T, 1) - 1;
    newNodeCount = numel(keepIdx);
    oldToNew = zeros(1, oldNodeCount);
    oldToNew(keepIdx) = 1:newNodeCount;

    TwNodes = zeros(newNodeCount, n);
    for r = 1:newNodeCount
        oldRow = keepIdx(r);
        row = T(oldRow, :);

        % Remap parent pointer.
        oldParent = row(parentCol);
        if oldParent == 0
            row(parentCol) = 0;
        else
            row(parentCol) = oldToNew(oldParent);
        end

        % Rebuild transition/target pairs, skipping filtered-out targets.
        writeT = transColStart;
        writeN = nodeColStart;
        readT = transColStart;
        readN = nodeColStart;
        while readT < n && row(readT) ~= 0
            targetOld = row(readN);
            if targetOld > 0 && targetOld <= oldNodeCount && oldToNew(targetOld) > 0
                row(writeT) = row(readT);
                row(writeN) = oldToNew(targetOld);
                writeT = writeT + 2;
                writeN = writeN + 2;
            end
            readT = readT + 2;
            readN = readN + 2;
        end

        % Zero trailing pair columns after compacting.
        row(writeT:end) = 0;
        TwNodes(r, :) = row;
    end

    % Metadata row: PNCT_plottree only needs column 1 = number of places.
    meta = zeros(1, n);
    meta(1) = T(end, 1);
    Tw = [TwNodes; meta];
end

