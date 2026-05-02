% Example-10: Cotree example-2
% This example is taken from Cassandras & Lafortune, p.253, ex.10

clear all; clc;
pns = pnstruct('cotree_10_pdf');
dyn.m0 = {'p1',1};
pni = initialdynamics(pns, dyn);
cotree(pni, 1, 1);
