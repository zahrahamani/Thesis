% COTREE Example-10G
% PDF File

function [png] = cotree_10G_def()
%        [png] = cotree_10G_def()

png.PN_name = 'COTREE Example 10G';
png.set_of_Ps = {'p1', 'p2', 'p3', 'p4', 'p5'};
png.set_of_Ts = {'t1', 't2', 't3', 't4', 't5'};
png.set_of_As = {'p1','t1',1, 'p4','t1',1, 't1','p2',1, ...  % t1
                 'p3','t2',1, 'p5','t2',1, 't2','p4',1, ...  % t2
                 'p2','t3',1, 't3','p1',1, 't3','p3',1, ...  % t3
                 'p1','t4',1, 'p3','t4',1, 't4','p5',1, ...  % t4
                 'p5','t5',1, 't5','p1',1, 't5','p3',1, ...  % t5
                };
            