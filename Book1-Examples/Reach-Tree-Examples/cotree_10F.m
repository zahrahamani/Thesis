% Example-10F: COTREE Example-10F
% the main file to run simulation 

clear all; clc; close all;
spng = pnstruct('cotree_10F_pdf');
dyn.m0 = {'p1',2, 'p2',2, 'p3',2};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0, 0);


%plotCOTREE(COTREE, {'p1',3,'p2',4,'wp3',1})
%plotCOTREE(COTREE)
plotCOTREE(COTREE, {'p1',1,'p3',4})
%plotCOTREE_experimental_horizontal(COTREE)