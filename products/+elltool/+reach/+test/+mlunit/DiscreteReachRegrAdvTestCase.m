classdef DiscreteReachRegrAdvTestCase < ...
        elltool.reach.test.mlunit.AReachRegrAdvTestCase
    methods
        function self = DiscreteReachRegrAdvTestCase(varargin)
            self = self@elltool.reach.test.mlunit.AReachRegrAdvTestCase(...
                elltool.linsys.LinSysDiscreteFactory(), ...
                elltool.reach.ReachDiscreteFactory(), ...
                varargin{:});
        end
    end
end