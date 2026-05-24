% COTREE Example-10G
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10G_pdf');
dyn.m0 = {'p1',3, 'p4',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 1, 1);
plotCOTREE(COTREE);