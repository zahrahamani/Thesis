% Example-09: COTREE Example-01
% fig 4.4, p.232 Cassandras book
clear all; clc;

pns = pnstruct('cotree_09_pdf');
dyn.m0 = {'p1',2, 'p4',1};
pni = initialdynamics(pns, dyn);
CT = cotree(pni, 0, 0); % cotree: plot graphically, as well as ASCII text
plotCOTREE(CT)
%plotCOTREE_experimental_horizontal(CT)

