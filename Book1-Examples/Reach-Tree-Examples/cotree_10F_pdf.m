% Example-10F: COTREE Example-10F
% PDF File

function [png] = cotree_10F_def()
%        [png] = cotree_10F_def()

png.PN_name = 'COTREE Example 10F';
png.set_of_Ps = {'p1', 'p2', 'p3'};
png.set_of_Ts = {'t1', 't2'};
png.set_of_As = {'p1','t1',1, 'p2','t1',2, 't1','p3',2, ...  % t1
                 'p3','t2',1, 't2','p1',1, 't2','p2',2};     % t2
             