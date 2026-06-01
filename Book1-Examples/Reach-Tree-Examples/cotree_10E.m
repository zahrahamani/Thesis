% Example-10E: COTREE Example-10E
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10E_pdf');
dyn.m0 = {'p1',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0, 0);

plotCOTREE(COTREE)
plotCOTREE(COTREE,{'p2',1,'p3',3,'p4',2})