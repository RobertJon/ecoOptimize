% This file is part of ecoOptimize, a code to optimize a design model for 
% minimum eco impacts subject to functional requirements.
% 
% Copyright (C) 2020 Ciarán O'Reilly <ciaran@kth.se>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.% 
% 
% main.m

restart=1;

if restart
  
  clear all
  clear global
  addpath('.') %path to material database [you could pick a different material database]
  addpath('../GCMMA-MMA-code-1.5') %path to GCMMA MATLAB functions
  addpath('../beamEB') %path to constraint solver [you could add a different solver]
  
  %% load material database
  global materialsData
  materialsData=importdata('materialData.mat');
  
  %% initiate model of the panel
  global model
  model=initModelSandwich; %define the model in function
  model=ecoOptimizeFuncs.blendMaterials(model,materialsData); %blend materials from database according to alpha
  model=ecoOptimizeFuncs.updateDependentVars(model);
  figure(1), clf, dispModel(model,0)
  
  %% set optimisation params
  xval=[model.H(1) model.H(2) model.H(3) model.alpha(1,1) model.alpha(1,2) model.alpha(1,3)]';
  xnam={'H(1)' 'H(2)' 'H(3)' 'alpha(1,1)' 'alpha(1,2)' 'alpha(1,3)'}';
  xmin=[0.001 0.001 0.001 0 0 0]';
  xmax=[0.2 0.2 0.2 1 1 1]';
  
  %% initiate GCMMA
  gcmma=GCMMAFuncs.init(@ecoOptimizeFuncs.optFuncs,xval,xnam,xmin,xmax);

end

%% run GCMMA
disp(['Optimizing for: ',model.objfunc])
gcmma.displive=1;
% figure(2), clf, gcmma.plotlive=1;
gcmma.maxoutit=30;
[gcmma,xval]=GCMMAFuncs.run(gcmma);
[f0val,fval]=ecoOptimizeFuncs.optFuncs(xval,xnam,false);

%% view results
figure(2), clf, GCMMAFuncs.plotIter(gcmma)
figure(1), dispModel(model,1)
mass=ecoOptimizeFuncs.computeMass(model)
LCE=ecoOptimizeFuncs.computeLCE(model)
LCCO2=ecoOptimizeFuncs.computeLCCO2(model)
LCCost=ecoOptimizeFuncs.computeLCCost(model)



%% FUNCTIONS

%%
function model=initModelSandwich
  model.objfunc='LCE';
  model.fmax=[1e-3];
  model.fscale=[1e3];
  model.driveDistTotal=1e5;
  model.solver='beamEBAna';
  model.loadcase='simple_pt';
  model.P=-1e4;
  model.xP=1;
  model.L=2;
  model.xsection='layered';
  model.B=1;
  model.H=[0.05 0.05 0.05];
  model.material={'GFRP' 'PUR' 'GFRP';'CFRP' 'PVC' 'CFRP'};
  model.alpha=[0.3 0.4 0.5];
end

%%
function dispModel(model,fill)
N=max([numel(model.B) numel(model.H)]);
B=repmat(model.B,1,N-numel(model.B)+1);
H=repmat(model.H,1,N-numel(model.H)+1);
H0=([0 cumsum(H(1:end-1))]-sum(H)/2);
B0=-B/2;
C=colormap;
for i=1:N
  R=rectangle('Position',[B0(i) H0(i) B(i) H(i)]);
  if fill
    set(R,'Facecolor',C(50*(i-1)+1,:))
  end
end
axis([B0(i)-B(i)/10 B0(i)+B(i)+B(i)/10 H0(i)-H(i)/10 H0(i)+H(i)+H(i)/10])
axis auto, axis equal
xlabel('b [m]'), ylabel('h [m]')
end