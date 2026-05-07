function [png] = fms_pdf()
png.PN_name = 'FMS';
%%%%%%% set of places
png.set_of_Ps = {'pIB1','pIB2','pOB', 'pC1','pC2', 'pR1','pR2','pR3','pR4', ... 
     'poC1','poC2','piM1','poM1', 'piM2',...
     'poM2','pi2AS','pi1AS','po1AS','po2AS','poAS','piPS','piCK'};  
%%%%%%% set of transitions             
png.set_of_Ts = {'tC1','tC2','tM1','tM2','tAS','tPS',...
                 'tC1M1','tC2M2','tM1AS','tM2AS','tAP','tPCK'}; 
%%%%%%% set of arcs             
png.set_of_As = {...
     'pIB1','tC1',1, 'pC1','tC1',1, 'tC1','poC1',1, ...  %tC1
     'pR1','tC1M1',1, 'poC1','tC1M1',1,...%tC1M1
     'tC1M1','piM1',1, 'tC1M1','pC1',1, ...  %tC1M1
     'piM1','tM1',1, 'tM1','poM1',1, ... %tM1
     'poM1','tM1AS',1, 'po1AS','tM1AS',1,... %tM1AS
     'tM1AS','pi1AS',1, 'tM1AS','pR1',1, ... %tM1AS
     ...
     'pIB2','tC2',1, 'pC2','tC2',1, 'tC2','poC2',1, ...  %tC2
     'pR2','tC2M2',1, 'poC2','tC2M2',1,...%tC2M2
     'tC2M2','piM2',1, 'tC2M2','pC2',1,...  %tC2M2
     'piM2','tM2',1, 'tM2','poM2',1, ... %tM2     
     'poM2','tM2AS',1, 'po2AS','tM2AS',1,... %tM2AS
     'tM2AS','pi2AS',1, ... %tM2AS
     ...
     'pi1AS','tAS',1, 'pi2AS','tAS',1, 'pR3','tAS',1,...  %tAS
     'tAS','po1AS',1, 'tAS','po2AS',1, 'tAS','poAS',1, 'tAS','pR2',1, ... %tAS    
     'poAS','tAP',1, 'tAP','piPS',1, ... %tAP
     'piPS','tPS',1, 'pR4','tPS',1, ... % tPS
     'tPS','pR4',1, 'tPS','piCK',1, ... % tPS
     'piCK','tPCK',1, 'tPCK','pR3',1, 'tPCK','pOB',1 ... % tPCK
     };
