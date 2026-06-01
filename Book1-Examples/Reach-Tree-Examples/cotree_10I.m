% COTREE Example-10H
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10I_pdf');
dyn.m0 = {'p0',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0, 0);

plotCOTREE(COTREE)



