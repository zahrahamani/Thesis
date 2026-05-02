% Example-09: COTREE Example-1 : fig 4.4, p.232 Cassandras book
function [png] = cotree_09_pdf()

png.PN_name = 'COTREE Example-09';
png.set_of_Ps = {'p1', 'p2', 'p3', 'p4'};
png.set_of_Ts = {'t1','t2', 't3'};
png.set_of_As =  {'p1', 't1', 1, 't1', 'p2', 1, 't1', 'p3', 1,...
    'p2','t2',1, 'p3','t2',1, 't2','p2',1, 't2','p4',1,...
    'p3','t3',1, 'p1','t3',1, 'p4', 't3', 1};   