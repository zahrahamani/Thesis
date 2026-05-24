% COTREE Example-10H
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10H_pdf');
dyn.m0 = {'p1',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 1, 1);
plotCOTREE(COTREE,{'p2',3})
