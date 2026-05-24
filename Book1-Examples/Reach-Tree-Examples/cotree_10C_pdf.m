% Example-10C: COTREE Example-10C
% PDF File

function [png] = cotree_10C_def()
%        [png] = cotree_10C_def()

png.PN_name = 'COTREE Example 10C';
png.set_of_Ps = {'p1', 'p2', 'p3'};
png.set_of_Ts = {'t1','t2', 't3'};
png.set_of_As = {'p1','t1',1, 't1','p2',1, ...  % t1
                 'p2','t2',1, 't2','p3',1, ...  % t2
                 'p2','t3',1, 't3','p1',1};     % t3
