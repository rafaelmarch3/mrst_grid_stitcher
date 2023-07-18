function v = transfer_example_1(model, state, conn_id, nncs_trans)
        
        %% v is a cell array containing fluxes of water and oil for all nnc connections
        v = {};
                 
        %% Get Neighbors
        nb1 = model.operators.N(conn_id,1);
        nb2 = model.operators.N(conn_id,2);
        
        %% Functions
        mob = model.getProps(state, 'FaceMobility');
        dp = model.getProps(state, 'PhasePotentialDifference');
        
        %% Fluxes
        v{1} = -nncs_trans.*mob{1}(conn_id).*dp{1}(conn_id);
        v{2} = -nncs_trans.*mob{2}(conn_id).*dp{2}(conn_id);
            

end