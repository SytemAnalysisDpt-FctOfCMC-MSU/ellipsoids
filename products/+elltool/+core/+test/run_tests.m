function result=run_tests(varargin)
runner = mlunitext.text_test_runner(1, 1);
suite = mlunitext.test_suite.fromTestCaseNameList({
      'elltool.core.test.mlunit.PolarIllCondTC',...
      'elltool.core.test.mlunit.EllipsoidIntUnionTC',...
      'elltool.core.test.mlunit.EllipsoidTestCase',...
      'elltool.core.test.mlunit.EllipsoidSecTestCase',...
      'elltool.core.test.mlunit.HyperplaneTestCase',...
      'elltool.core.test.mlunit.GenEllipsoidPlotTestCase',...
     'elltool.core.test.mlunit.GenEllipsoidSecTC',...
     'elltool.core.test.mlunit.GenEllipsoidTestCase',...
     'elltool.core.test.mlunit.ElliIntUnionTCMultiDim',...
     'elltool.core.test.mlunit.EllTCMultiDim',...
     'elltool.core.test.mlunit.EllSecTCMultiDim',...
     'elltool.core.test.mlunit.MPTIntegrationTestCase',...
     'elltool.core.test.mlunit.EllipsoidPlotTestCase',...
     'elltool.core.test.mlunit.EllAuxTestCase',...
     'elltool.core.test.mlunit.HyperplanePlotTestCase',...
     'elltool.core.test.mlunit.EllipsoidMinkPlotTestCase',...
     'elltool.core.test.mlunit.EllipsoidBasicSecondTC',...
     'elltool.core.test.mlunit.EllipsoidDispStructTC',...
     'elltool.core.test.mlunit.HyperplaneDispStructTC',...
     'elltool.core.test.mlunit.EllMinkdiffPlotTC',...
     'elltool.core.test.mlunit.EllMinkpmPlotTC',...
     'elltool.core.test.mlunit.EllMinkmpPlotTC',...
     'elltool.core.test.mlunit.EllMinksumPlotTC'...
    }, varargin);
%
suite1Obj=mlunitext.test_suite.fromTestCaseNameList(...
    'elltool.core.test.mlunit.PrameterizedTC',...
    {@elltool.core.test.mlunit.TEllipsoid,'marker','Ellipsoid'});
%
suite2Obj=mlunitext.test_suite.fromTestCaseNameList(...
    'elltool.core.test.mlunit.PrameterizedTC',...
    {@elltool.core.test.mlunit.TGenEllipsoid,'marker','GenEllipsoid'});
%
suite3Obj=mlunitext.test_suite.fromTestCaseNameList(...
    'elltool.core.test.mlunit.PrameterizedTC',...
    {@hyp,'marker','Hyperplane'});

suite2dLegendAllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {2, {@elltool.core.test.mlunit.TEllipsoid,...
    @elltool.core.test.mlunit.TGenEllipsoid,@hyp}, [2,2,1], 'marker','all2d'});

suite2dLegendEllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {2, {@elltool.core.test.mlunit.TEllipsoid}, 2, 'marker','ellipsoid2d'});

suite2dLegendHypObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {2, {@hyp}, 1, 'marker','hyperplane2d'});

suite2dLegendGenEllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {2, {@elltool.core.test.mlunit.TGenEllipsoid}, 2, 'marker','GenEllipsoid2d'});

suite3dLegendAllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {3, {@elltool.core.test.mlunit.TEllipsoid,...
    @elltool.core.test.mlunit.TGenEllipsoid,@hyp}, [1,1,1], 'marker','all3d'});

suite3dLegendEllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {3, {@elltool.core.test.mlunit.TEllipsoid}, 1, 'marker','ellipsoid3d'});

suite3dLegendHypObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {3, {@hyp}, 1, 'marker','hyperplane3d'});

suite3dLegendGenEllObj = mlunitext.test_suite.fromTestCaseNameList(...
   'elltool.core.test.mlunit.ParameterizedPlotTC',...
   {3, {@elltool.core.test.mlunit.TGenEllipsoid}, 1, 'marker','GenEllipsoid3d'});

suiteObj=mlunitext.test_suite.fromSuites(suite, suite1Obj,...
    suite2Obj,suite3Obj, suite2dLegendAllObj, suite2dLegendEllObj,...
    suite2dLegendHypObj, suite2dLegendGenEllObj, suite3dLegendAllObj,...
    suite3dLegendEllObj, suite3dLegendHypObj, suite3dLegendGenEllObj);

result=runner.run(suiteObj);
    function h = hyp(hypNormArr,hypConstArr,varargin)
        h = elltool.core.test.mlunit.THyperplane(hypNormArr, hypConstArr(1),varargin{:});
    end
end