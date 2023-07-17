classdef GridStitcher
    %FRACTURED_DOMAIN_MANAGER
    
    properties
        
    end
    
    methods
        function obj = GridStitcher()
            
        end
        
        
        function model = stitch(obj, model, grids, rocks, fluids, connections, transfer_models, varargin)
            
            %% Initializing StitchedGrids
            model.G.StitchedGrids = struct();
            
            %% Add transfer
            model.G.StitchedGrids.transfer_models = transfer_models;
            
            %% Step 1: we increase the number of cells 
            number_new_cells = 0;
            all_centroids = model.G.cells.centroids;
            for i = 1:length(grids)
                number_new_cells = number_new_cells + grids{i}.cells.num;
                all_centroids = [all_centroids; grids{i}.cells.centroids]; %#ok<AGROW>
            end
            model.G.cells.centroids = all_centroids;
            model.G.StitchedGrids.total_cell_num = model.G.cells.num + number_new_cells;
            
            %% Updating G.cells.num
            base_grid_cell_num = model.G.cells.num;
            model.G.cells.num = model.G.StitchedGrids.total_cell_num; %(DO WE REALLY NEED THIS?)
            
            %% Step 2: setting the neighbor list
            % These are the base grid neighbors
            N = model.operators.N; 
            % These are stitched grid neighbors
            op_list = {}; % Let's store these guys since they are going to be useful later
            start_index = base_grid_cell_num;
            for i = 1:length(grids)
                op_list{i} = setupOperatorsTPFA(grids{i}, rocks{i}); %#ok<AGROW>
                N = [N; start_index + op_list{i}.N]; %#ok<AGROW>
                start_index = start_index + grids{i}.cells.num;
            end
            
            %% Counting connections
            model.G.StitchedGrids.nnc_ids = size(N, 1) + 1: ...
                                            size(N, 1) + size(connections, 1);
            
            
            % These are the non-neighboring connections
            for i = 1:size(connections, 1)
                N = [N; connections(i,:)]; %#ok<AGROW>
            end
            model.operators.N = N;
           
            
            
            
            
            %% Step 3: update pore volume
            for i = 1:length(grids)
                model.operators.pv = [model.operators.pv; op_list{i}.pv]; 
            end
            
            %% Step 4: we update the remaining operators (transmissibility treated later)
            nf = size(N,1);
            nc = model.G.StitchedGrids.total_cell_num;
            D = sparse([(1:nf)'; (1:nf)'], N, ones(nf,1)*[-1 1], nf, nc);
            model.operators.Div = @(x) -D'*x;
            model.operators.Grad = @(x) D*x;
            model.operators.avg   = @(x) 0.5 * (x(N(:,1)) + x(N(:,2)));
            model.operators.upw   = @(flag, x) flag.*x(N(:, 1)) + ~flag.*x(N(:, 2));
            M = sparse((1 : nf) .' * [1, 1], N, repmat(0.5, [nf, 2]), nf, nc);
            model.operators.M = M;
            model.operators.faceAvg = @(x) M*x;
            
            
            
            %% Step 5: we update the transmissibilities
            for i = 1:length(grids)
                model.operators.T = [model.operators.T; op_list{i}.T]; 
            end
            for i = 1:size(connections, 1)
                model.operators.T = [model.operators.T; 0.0]; 
            end
            
            % faceUpstr - as multiplication with matrix
            model.operators.faceUpstr = @(flag, x) faceUpstr(flag, x, N, [nf, nc]);

            model.operators.splitFaceCellValue = @(operators, flag, x) ...
               splitFaceCellValue(operators, flag, x, [nf, nc]);
            
            %% Step 6: Let's remove all other operators to ensure we are not using rubbish information
%             model.operators = rmfield(model.operators, 'internalConn');
%             model.operators = rmfield(model.operators, 'T_all');
%             model.operators = rmfield(model.operators, 'splitFaceCellValue');
%             model.operators = rmfield(model.operators, 'AccDiv');
%             model.operators = rmfield(model.operators, 'faceAvg');
%             model.operators = rmfield(model.operators, 'faceUpstr');
%             model.operators = rmfield(model.operators, 'gdz');
%             model.operators = rmfield(model.operators, 'pv');
%             model.operators = rmfield(model.operators, 'M');
%             model.operators = rmfield(model.operators, 'C');
            
            %% Step 7: Replacing the State Functions
            model.PVTPropertyFunctions = GridStitcherPVTPropertyFunctions(model);
            model.FlowPropertyFunctions = GridStitcherFlowPropertyFunctions(model);
            model.FlowDiscretization = GridStitcherFlowDiscretization(model);
            
            %% Final Step: there is a problem when outputFluxes = 1
            model.outputFluxes = 0;
            
            
                                                        
        end
        
    end
   
end

