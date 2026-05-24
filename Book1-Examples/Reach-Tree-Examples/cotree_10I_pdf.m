% COTREE Example-10I
% PDF File

function [png] = cotree_10I_def()
%        [png] = cotree_10I_def()

png.PN_name = 'COTREE Example 10I';
png.set_of_Ps = {'p0', 'p1', 'p2'};
png.set_of_Ts = {'t1', 't2', 't3'};
png.set_of_As = {'p0','t1',1, 't1','p1',1, ...  % t1
                 'p0','t2',1, 't2','p2',1, ...  % t2
                 'p1','t3',1, 't3','p1',1, ...  % t3
                };
            