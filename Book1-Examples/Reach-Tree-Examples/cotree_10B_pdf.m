% Example-10B: COTREE Example-10B
% PDF File

function [png] = cotree_10B_def()
% function [png] = cotree_10B_def()

png.PN_name = 'COTREE Example 10B';
png.set_of_Ps = {'p1', 'p2', 'p3', 'p4'};
png.set_of_Ts = {'t1','t2', 't3', 't4'};
png.set_of_As =  {'p1', 't1', 1, 't1', 'p2', 1,...          % t1
                  'p2','t2',1, 't2','p1',1, ...             % t2
                  'p2','t3',1, 'p4','t3',1, 't3','p3',1,... % t3
                  'p3','t4',1, 't4', 'p4', 1};              % t4