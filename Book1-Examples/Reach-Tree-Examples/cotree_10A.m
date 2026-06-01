% Exam Business Process Modeling @SUT
% June 2023 

clear all; clc; close all;

spng = pnstruct('cotree_10A_pdf');
dyn.m0 = {'p1',3};
pni = initialdynamics(spng, dyn);
COTREE = cotree(pni, 0, 0);
plotCOTREE(COTREE)

