function results=run_discr_tests(varargin)

confList = {
    'discrFirstTest';
    'discrSecondTest';
    'demo3thirdTest';
    'checkTime';
};

suiteDefList = {
	struct(...
    'defConstr', @gras.ellapx.lreachuncert.probdef.LReachContProblemDef,...
    'dynConstr', @gras.ellapx.lreachuncert.probdyn.LReachDiscrForwardDynamics,...
    'confs', {confList},...
    'TC', 'gras.ellapx.lreachuncert.probdyn.test.mlunit.ProbDynUncertDiscrTC'...
    );
};

import gras.ellapx.lreachplain.probdyn.test.run_discr_tests_from_suitedef;
results=run_discr_tests_from_suitedef(suiteDefList);
%results=[];
end