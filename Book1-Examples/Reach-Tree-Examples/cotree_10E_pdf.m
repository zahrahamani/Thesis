% Example-10E: COTREE Example-10E
% PDF File

function [png] = cotree_10E_def()
%        [png] = cotree_10E_def()

png.PN_name = 'COTREE Example 10E';
png.set_of_Ps = {'p1', 'p2', 'p3', 'p4'};
png.set_of_Ts = {'t1','t2', 't3'};
png.set_of_As = {'p1','t1',1, 't1','p2',1, 't1','p3',1, ...  % t1
                 'p2','t2',1, 't2','p1',1, ...  % t2
                 'p2','t3',1, 'p3','t3',1, ...  % t3
                 't3','p3',1, 't3','p4',1};     % t3
