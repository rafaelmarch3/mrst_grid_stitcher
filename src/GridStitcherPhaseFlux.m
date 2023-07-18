classdef GridStitcherPhaseFlux < StateFunction
    properties

    end
    
    methods
        function fm = GridStitcherPhaseFlux(model)
            fm@StateFunction(model);
            fm = fm.dependsOn({'FaceMobility', 'PermeabilityPotentialGradient'});
        end

        
        function v = evaluateOnDomain(prop, model, state)
            
            [mob, kgrad] = prop.getEvaluatedDependencies(state,...
                'FaceMobility', 'PermeabilityPotentialGradient');
            
            %% Standard flux evaluation
            v = cellfun(@(x,y)-x.*y, mob, kgrad, 'UniformOutput', false);
            
            %% Compute fluxes between mutli-continuum domains
            nnc_ids = model.G.StitchedGrids.nnc_ids;
            for j = 1:length(nnc_ids)
                conn_id = nnc_ids(j);
                vf = model.G.StitchedGrids.transfer_models{j}(model, state, conn_id);
                
                for i = 1:numel(mob)
                    v{i}(conn_id) = vf{i};
                end
            end
            
            disp(v{1}.val);
            disp(v{2}.val);
            disp('----');
            
        end
    end
end