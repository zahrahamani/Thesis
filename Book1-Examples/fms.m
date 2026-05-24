clear all; clc; close all;
global global_info
global_info.STOP_AT = 100; % stop simulation after 100 TU

pns = pnstruct('fms_pdf'); % declare the PDF

IntialTOKinpts = 2;

% declare the initial markings
dyn.m0 = {'pIB1',IntialTOKinpts, 'pIB2',IntialTOKinpts, ...
          'pC1',1,'pC2',1,...
          'pR1',1,'pR2',1,'pR3',1,'pR4',1, 'po1AS',1,'po2AS',1};

% declare the firing times of the transitons
dyn.ft = {'tC1',10,'tC2',10, 'tC1M1',2,'tC2M2',2,...
          'tM1',5,'tM2',10,'tM1AS',2,'tM2AS',2,...
          'tAS',7, 'tAP',2,'tPS',8, 'tPCK',10};

% combine static and dynamic parts to form the Petri net 
pni = initialdynamics(pns, dyn);

CT = cotree(pni,1,1);

% Example with custom start state
%plotCOTREE(CT, pns, {'pC1',1,'pC2',1,'pR1',1,'pR4',1,'pi1AS',1,'pi2AS',1,'piCK',1});
%plotCOTREE(CT, {'pC1',1,'pC2',1,'pOB',1,'pR1',1,'pR3',1,'pR4',1,'pi1AS',1,'pi2AS',1});
 plotCOTREE(CT)
