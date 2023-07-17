function v = transfer_example_1(model, state, conn_id)
        
        %% v is a cell array containing fluxes of water and oil for all nnc connections
        vf = {};
                 
        %% Get Neighbors
        nb1 = model.operators.N(conn_id,1);
        nb2 = model.operators.N(conn_id,2);
        
        %% Standard flux
        [mob, kgrad] = model.getProps(state,...
                'FaceMobility', 'PermeabilityPotentialGradient');
            
        %% Standard flux evaluation
        v = cellfun(@(x,y)-x.*y, mob, kgrad, 'UniformOutput', false);
        
        vf{1} = v{1}(conn_id);
        vf{2} = v{2}(conn_id);
        
        v = vf;
        
        
%         %% Saturations
%         s = model.getProps(state,'saturation');
%         
%         %% Saturation at both neighbor cells
%         swnb1 = s{1}(nb1);
%         swnb2 = s{1}(nb2);
% 
%         snnb1 = 1 - s{1}(nb1);
%         snnb2 = 1 - s{1}(nb2);        
%         
%         %% Cell volume
%         vb = model.G.cells.volumes(1);
%         
%         %% Transfer rate parameters
%         beta = 1e-9;
%         
%         %% Transfer for water
%         v{1} = vb.*beta.*(snnb1-snnb2);
%         v{2} = -v{1};
        

end