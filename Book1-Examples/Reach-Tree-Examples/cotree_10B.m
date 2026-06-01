% Example-10B: COTREE Example-10B : 
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10B_pdf');
dyn.m0 = {'p1',2, 'p4',2};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0, 0);
plotCOTREE(COTREE,{'p4', 2})