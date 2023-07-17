classdef GridStitcherGravityPotentialDifference < StateFunction
    properties
        saturationWeighting = false;
    end
    
    methods
        function gp = GridStitcherGravityPotentialDifference(varargin)
            gp@StateFunction(varargin{:});
            gp = gp.dependsOn('Density', 'PVTPropertyFunctions');
            if gp.saturationWeighting
                gp = gp.dependsOn('s', 'state');
            end
        end
        function gRhoDz = evaluateOnDomain(prop, model, state)
            act = model.getActivePhases();
            nph = sum(act);
            
            gRhoDz = cell(1, nph);
            % We cannot call model.getGravityGradient(), since
            % it uses G.cells.centroids
            g = model.getGravityVector();
            c = model.G.cells.centroids;
            gdz = model.operators.Grad(c) * g';

            if norm(model.gravity) > 0
                nm = model.getPhaseNames();
                rho = model.getProp(state, 'Density');
                avg = model.operators.faceAvg;
                for i = 1:nph
                    if prop.saturationWeighting
                        s = model.getProp(state, ['s', nm(i)]);
                        rhof = avg(s.*rho{i})./max(avg(s), 1e-8);
                    else
                        rhof = avg(rho{i});
                    end
                    gRhoDz{i} = - rhof.*gdz;
                end
            else
                [gRhoDz{:}] = deal(gdz);
            end
        end
    end
end