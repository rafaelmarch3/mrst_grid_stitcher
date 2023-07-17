%% Adding to path
addpath('..\src\');

%% The usual stuff
clear;
clc;
close all;

%% Add modules
mrstModule add ad-blackoil ad-core ad-props mrst-gui hwu-fractures

%% Grid 1
nx = 7;
ny = 1;
nz = 1;
x_size = 100;
y_size = 10;
z_size = 10;
G1 = cartGrid([nx, ny, nz], [x_size, y_size, z_size]);
G1 = computeGeometry(G1);

%% Grid 2
nx = 7;
ny = 1;
nz = 1;
x_size = 100;
y_size = 10;
z_size = 10;
G2 = cartGrid([nx, ny, nz], [x_size, y_size, z_size]);
G2 = computeGeometry(G2);

%% Set up rock properties
rock1 = makeRock(G1, 1*milli*darcy, .1);
rock2 = makeRock(G1, 0.001*milli*darcy, .1);
%% Set up fluid
fluid = initSimpleADIFluid('phases', 'WO',...
                                'c', [1e-11,1e-11]/psia,...
                                'n', [2,2],...
                                'mu',[1, 1]*centi*poise,...
                                'rho',[1000, 0.01]);

%% Set up model
gravity reset off;
model = TwoPhaseOilWaterModel(G1, rock1, fluid);
model = model.validateModel();

%% Connections
cells_orig = (1 : G1.cells.num)';
cells_new = (G1.cells.num+1 : G1.cells.num + G2.cells.num)';
connections = [cells_orig, cells_new]; % These are global ids

%% Transfer
transfer = @(model, state, conn_id)transfer_example_1(model, state, conn_id);

%% Transfer models
transfer_models = cell(size(connections,1),1);
for i = 1:length(transfer_models)
    transfer_models{i} = transfer;
end
                            
%% Stitching grids            
gridStitcher = GridStitcher();
model = gridStitcher.stitch(model, {G2}, {rock2}, {fluid}, connections, transfer_models);

% disp(model.operators)

%% Boundary conditions
bc = [];
src = [];
src = addSource(src, 7, 1e-6, 'sat', [0, 1]);
src = addSource(src, 8, -1e-6, 'sat', [0, 1]);
%% Initializing state 
W = [];
state = initResSol(model.G, 1000*psia, [1, 0]);
state.wellSol = initWellSolAD(W, model, state);

%% Solver
solver = NonLinearSolver();

%% Figure
fig1 = figure('Position',[100,100,600,600]);
fig1.Color = 'w';

%% Time loop
dt = 1000*day;
tmax = 1000*dt;
t = 0;
while t<=tmax
    
    disp(['Time = ',num2str(t/day), ' days'])
    state = solver.solveTimestep(state, dt, model, 'bc', [], 'src', src);
    
%     aux = G.cells.num;
%     G.cells.num = 7;
    
    figure(fig1)
    subplot(2,1,1);
    colormap(flipud(jet));
    p = plotCellData(G1,state.s(1:7,2));
    p.EdgeAlpha = 0.3;
    colorbar;
    caxis([0,1]);
    set(gca,'FontSize',16);
%     axis equal;
    view(-21, 22);
    xlabel('x')
    ylabel('y')
%     hold on;
    drawnow;
    
    subplot(2,1,2);
    colormap(flipud(jet));
    p = plotCellData(G2,state.s(8:14,2));
    p.EdgeAlpha = 0.3;
    colorbar;
    caxis([0,1]);
    set(gca,'FontSize',16);
%     axis equal;
view(-21, 22);
    xlabel('x')
    ylabel('y')
%     hold on;
    drawnow;
    
    
    t = t+dt;
    
end