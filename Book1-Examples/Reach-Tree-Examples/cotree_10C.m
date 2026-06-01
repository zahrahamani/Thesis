% Example-10C: COTREE Example-10C : 
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10C_pdf');
dyn.m0 = {'p1',4};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0);
plotCOTREE(COTREE)