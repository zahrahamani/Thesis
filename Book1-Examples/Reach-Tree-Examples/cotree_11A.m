% Example-11-01: COTREE Example-01: 
% fig 4.4, p.232 Cassandras book
clear all; clc; close all;
pns = pnstruct('cotree_11A_pdf');
dyn.m0 = {'p1',2, 'p4',1};
pni = initialdynamics(pns, dyn);
COTREE = cotree(pni, 1,1); 
