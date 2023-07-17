classdef GridStitcherFlowDiscretization < FlowDiscretization
    % Flow discretization for fractured domains
    
    methods
        function props = GridStitcherFlowDiscretization(model)
            % Call parent constructor
            props@FlowDiscretization(model);
            % Replace state functions for gravity potential difference,
            % face mobility and phase flux with fractured domain variants
            props = props.setStateFunction('GravityPotentialDifference', GridStitcherGravityPotentialDifference(model));
            props = props.setStateFunction('FaceMobility', GridStitcherFaceMobility(model));
            props = props.setStateFunction('PhaseFlux', GridStitcherPhaseFlux(model));
        end
    end
    
end