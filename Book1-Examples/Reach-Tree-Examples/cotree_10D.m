% Example-10D: COTREE Example-10D 
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10D_pdf');
dyn.m0 = {'p1',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 1, 1);
plotCOTREE(COTREE)