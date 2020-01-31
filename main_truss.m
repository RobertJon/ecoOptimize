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
  addpath('.') %path to material database
  addpath('../trussJVW') %path to constraint solver
  
  %% select a material
  global materialsData
  materialsData=importdata('materialData.mat');
  
  %% initiate model of the panel
  global model material
  model=initModelTruss;
  material=ecoOptimizeFuncs.blendMaterials(model,materialsData);
  model=ecoOptimizeFuncs.updateMaterialProps(model,material);
  model=ecoOptimizeFuncs.updateDependentVars(model);
  figure(1), clf, hold on, axis equal, trussJVWFuncs.plotModel(model)
  
  %% solve for forces
  [force,freact]=trussJVWFuncs.computeMJoints(model);
  model.force=force;
  model.freact=freact;
  trussJVWFuncs.plotForce(model,force)
  trussJVWFuncs.displayForce(freact,force)
  
  %% set optimisation params
  xval=[model.D]';
  for i=1:numel(xval), xnam(i)={['D(',num2str(i),')']};end
  xmin=repmat([0],numel(xval),1);
  xmax=repmat([1],numel(xval),1);
  maxiter=30;
  
  %% initiate GCMMA
  gcmma=GCMMAFuncs.init(xval,xnam,xmin,xmax,maxiter);

end

%% run GCMMA
figure(2)
disp(['Optimizing for: ',model.objfunc])
[gcmma,xval]=GCMMAFuncs.run(gcmma,xval,xnam,xmin,xmax,true);
[f0val,fval]=ecoOptimizeFuncs.optFuncs(xval,xnam,false);

%% plot results
figure(2), clf, GCMMAFuncs.plotIter(gcmma)
delta=trussJVWFuncs.computeMVirtualWork(model,force);
figure(1), trussJVWFuncs.plotDelta(model,delta)
trussJVWFuncs.displayDelta(delta)
mass=sum(ecoOptimizeFuncs.computeMass(model))
LCE=ecoOptimizeFuncs.computeLCE(model)
LCCO2=ecoOptimizeFuncs.computeLCCO2(model)
LCCost=ecoOptimizeFuncs.computeLCCost(model)



%%
%% FUNCTIONS

function model=initModelTruss
  model.objfunc='Mass';
  model.fmax=[1e-2];
  model.fscale=[1e2];
  model.driveDistTotal=1e5;
  model.solver='trussJVW';
  model.node=[0 0; 1 0; 0.25 -0.05; 0.5 -0.05; 0.75 -0.05; 0.25 0; 0.5 0; 0.75 0]; %size nx2
  model.member=[1 3; 3 4; 4 5; 5 2; 1 6; 6 7; 7 8; 8 2; 3 6; 3 7; 7 4; 7 5; 5 8]; %size mx2
  model.react=logical([1 1; 0 1; 0 0; 0 0; 0 0; 0 0; 0 0; 0 0]); %size nx2
  model.load=[0 0; 0 0; 0 0; 0 0; 0 0; 0 0; 0 -1e4; 0 0]; %size nx2
  model.virt=logical([0 0; 1 0; 1 1; 1 1; 1 1; 1 1; 1 1; 1 1]); %size nx2
  model.xsection='circular';
  model.D=repmat([0.01],1,size(model.member,1));
  model.material=repmat({'Steel'},1,size(model.member,1));
  model.alpha=repmat([1],1,size(model.member,1));
end