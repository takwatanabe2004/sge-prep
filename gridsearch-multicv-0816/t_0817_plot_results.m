clear
% close all
pen = 'flass'; % {'elnet', 'grnet', 'flass','isotv'}
mod = 'RD';
% grp = 'LR-train_HR-test'; % {'LR-train_HR-test', 'HR-train_LR-test'}
grp = 'HR-train_LR-test';

load(['VOLdsamp_gender_gridcv_',mod,'v06_',pen,'_',grp,'.mat'])
x=log2(setup.gamgrid);
y=log2(setup.lamgrid);
figure
subplot(231),imagesc(x,y,test_results.acc'),impixelinfo,colorbar
subplot(232),imagesc(x,y,grid_results.acc(:,:,1)'),impixelinfo,colorbar
subplot(233),imagesc(x,y,grid_results.acc(:,:,2)'),impixelinfo,colorbar
subplot(234),imagesc(x,y,grid_results.acc(:,:,3)'),impixelinfo,colorbar
subplot(235),imagesc(x,y,grid_results.acc(:,:,4)'),impixelinfo,colorbar
subplot(236),imagesc(x,y,grid_results.acc(:,:,5)'),impixelinfo,colorbar

load(['VOLdsamp_gender_gridcv_',mod,'v12_',pen,'_',grp,'.mat'])
figure
subplot(231),imagesc(x,y,test_results.acc'),impixelinfo,colorbar
subplot(232),imagesc(x,y,grid_results.acc(:,:,1)'),impixelinfo,colorbar
subplot(233),imagesc(x,y,grid_results.acc(:,:,2)'),impixelinfo,colorbar
subplot(234),imagesc(x,y,grid_results.acc(:,:,3)'),impixelinfo,colorbar
subplot(235),imagesc(x,y,grid_results.acc(:,:,4)'),impixelinfo,colorbar
subplot(236),imagesc(x,y,grid_results.acc(:,:,5)'),impixelinfo,colorbar

load(['VOLdsamp_gender_gridcv_',mod,'v24_',pen,'_',grp,'.mat'])
figure
subplot(231),imagesc(x,y,test_results.acc'),impixelinfo,colorbar
subplot(232),imagesc(x,y,grid_results.acc(:,:,1)'),impixelinfo,colorbar
subplot(233),imagesc(x,y,grid_results.acc(:,:,2)'),impixelinfo,colorbar
subplot(234),imagesc(x,y,grid_results.acc(:,:,3)'),impixelinfo,colorbar
subplot(235),imagesc(x,y,grid_results.acc(:,:,4)'),impixelinfo,colorbar
subplot(236),imagesc(x,y,grid_results.acc(:,:,5)'),impixelinfo,colorbar