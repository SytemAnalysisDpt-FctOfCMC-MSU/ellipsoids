function  [plObj,nDim,isHold,bodyArr] = plotgeombodyarr(objClassName,rebuildOneDim2TwoDim,calcBodyPoints,plotPatch,varargin)
%
% plotgeombodyarr - plots objects in 2D or 3D.
%
%
% Usage:
%       plotgeombodyarr(objClassName,rebuildOneDim2TwoDim,calcBodyPoints,plotPatch,objArr,'Property',PropValue,...) - plots array of objClassName objects
%           using calcBodyPoints function to calculate points,  rebuildOneDim2TwoDim to rebuild one dim ibjects to two dim if it is needed,
%           plotPatch to plot objects with  setting properties
%
% Input:
%   regular:
%       objClassName:string - class of objects
%       rebuildOneDim2TwoDim: function with input bodyArr and output bodyArr and nDim
%       calcBodyPoints: function with input
%           ellsArr,nDim,lGetGridMat,fGetGridMat and output [xMat,fMat]
%       plotPatch: plotting function 
%       bodyArr:  objects: [dim11Size,dim12Size,...,dim1kSize] -
%                array of 2D or 3D objects. All objects in bodyArr
%                must be either 2D or 3D simutaneously.
%   optional:
%       color1Spec: char[1,1] - color specification code, can be 'r','g',
%                               etc (any code supported by built-in Matlab function).
%       body2Arr: objClassName: [dim21Size,dim22Size,...,dim2kSize] -
%                                           second ellipsoid array...
%       color2Spec: char[1,1] - same as color1Spec but for body2Arr
%       ....
%       bodyNArr: objClassName: [dimN1Size,dim22Size,...,dimNkSize] -
%                                            N-th objects array
%       colorNSpec - same as color1Spec but for bodyNArr.
%   properties:
%       'newFigure': logical[1,1] - if 1, each plot command will open a new figure window.
%                    Default value is 0.
%       'fill': logical[1,1]/logical[dim11Size,dim12Size,...,dim1kSize]  -
%               if 1, ellipsoids in 2D will be filled with color. Default value is 0.
%       'lineWidth': double[1,1]/double[dim11Size,dim12Size,...,dim1kSize]  -
%                    line width for 1D and 2D plots. Default value is 1.
%       'color': double[1,3]/double[dim11Size,dim12Size,...,dim1kSize,3] -
%                sets default colors in the form [x y z]. Default value is [1 0 0].
%       'shade': double[1,1]/double[dim11Size,dim12Size,...,dim1kSize]  -
%                level of transparency between 0 and 1 (0 - transparent, 1 - opaque).
%                Default value is 0.4.
%       'relDataPlotter' - relation data plotter object.
%       'priorHold':logical[1,1] - if true plot with hold on,
%       'postHold':logical[1,1] - if true, after plotting hold will be on ,
%       'plotBodies': double[1,1] number of plottingg objects (using if this number doesn't match with number of input objects)
%       Notice that property vector could have different dimensions, only
%       total number of elements must be the same.
% Output:
%   regular:
%       plObj: smartdb.disp.RelationDataPlotter[1,1] - returns the relation
%       data plotter object.
%       nDim: double[1,1] - dimension of objects,
%       isHold: logical[1,1] - true, if before plotting was hold on,
%       bodyArr: objClassName: [dim21Size,dim22Size,...,dim2kSize] - array of input objects
%
% $Author: <Ilya Lyubich>  <lubi4ig@gmail.com> $    $Date: <11 January 2013> $
% $Copyright: Moscow State University,
%            Faculty of Computational Mathematics and Cybernetics,
%            System Analysis Department 2013 $

import modgen.common.throwerror;
DEFAULT_LINE_WIDTH = 1;
DEFAULT_SHAD = 0.4;
DEFAULT_FILL = false;
N_PLOT_POINTS = 80;
SPHERE_TRIANG_CONST = 3;
[reg,~,plObj,isNewFigure,isFill,lineWidth,colorVec,shadVec,priorHold,postHold,plotBodies...
    isRelPlotterSpec,~,isIsFill,isLineWidth,isColorVec,isShad,~,isPostHold,isPlotBodies]=...
    modgen.common.parseparext(varargin,...
    {'relDataPlotter','newFigure','fill','lineWidth','color','shade','priorHold','postHold',...
    'plotBodies';...
    [],0,[],[],[],0,false,false,0;@(x)isa(x,'smartdb.disp.RelationDataPlotter'),...
    @(x)isa(x,'logical'),@(x)isa(x,'logical'),@(x)isa(x,'double'),...
    @(x)isa(x,'double'),...
    @(x)isa(x,'double'), @(x)isa(x,'logical'),@(x)isa(x,'logical'),@(x)isa(x,'double')});
checkIsWrongInput();
if ~isRelPlotterSpec
        if isNewFigure
            plObj=smartdb.disp.RelationDataPlotter();
        else
            plObj=smartdb.disp.RelationDataPlotter('figureGetNewHandleFunc',...
                @(varargin)gcf,'axesGetNewHandleFunc',@(varargin)gca);
        end
end
[bodyArr, bodyNum, uColorVec, vColorVec, isCharColor] = getParams(reg);
if isCharColor && isColorVec
    throwerror('ConflictingColor', 'Conflicting using of color property');
end
if isPlotBodies
    bodyPlotNum = plotBodies;
else
    bodyPlotNum = bodyNum;
end
nDim = max(dimension(bodyArr));
if nDim == 3 && isLineWidth
    throwerror('wrongProperty', 'LineWidth is not supported by 3D objects');
end
[colorVec, shadVec, lineWidth, isFill] = getPlotParams(colorVec, shadVec,...
    lineWidth, isFill);
checkIsWrongParams();
checkDimensions();
SData = setUpSData();
if nDim == 1
    [bodyArr,nDim] = rebuildOneDim2TwoDim(bodyArr);
end
[lGetGridMat, fGetGridMat] = calcGrid();
prepareForPlot();

rel=smartdb.relations.DynamicRelation(SData);
hFigure = get(0,'CurrentFigure');
if isempty(hFigure)
    isHold=false;
else
    hAx = get(hFigure,'currentaxes');
    if isempty(hAx)
        isHold=false;
    elseif ~ishold(hAx)
        if priorHold
            isHold = true;
        else
            if ~isRelPlotterSpec
                cla;
            end
            isHold = false;
        end
    else
    isHold = true;
    end
end
if isPostHold
    if postHold
        postFun = @axesSetPropDoNothingFunc;
    else
        postFun = @axesSetPropDoNothing2Func;
    end
else
    if isHold
        postFun = @axesSetPropDoNothingFunc;
    else
        postFun = @axesSetPropDoNothing2Func;
    end
end
if (nDim==2)
    plObj.plotGeneric(rel,@figureGetGroupNameFunc,{'figureNameCMat'},...
        @figureSetPropFunc,{},...
        @axesGetNameSurfFunc,{'axesNameCMat','axesNumCMat'},...
        @axesSetPropDoNothingFunc,{},...
        @plotCreateFillPlotFunc,...
        {'xCMat','faceCMat','clrVec','fill','shadVec', 'widVec','plotPatch'},'axesPostPlotFunc',postFun,'isAutoHoldOn',false);
    
elseif (nDim==3)
    plObj.plotGeneric(rel,@figureGetGroupNameFunc,{'figureNameCMat'},...
        @figureSetPropFunc,{},...
        @axesGetNameSurfFunc,{'axesNameCMat','axesNumCMat'},...
        @axesSetPropDoNothingFunc,{},...
        @plotCreatePatchFunc,...
        {'verCMat','faceCMat','faceVertexCDataCMat',...
        'shadVec','clrVec'},'axesPostPlotFunc',postFun,'isAutoHoldOn',false);
end





    function [lGetGrid, fGetGrid] = calcGrid()
        if nDim == 2
            lGetGrid = gras.geom.circlepart(N_PLOT_POINTS);
            fGetGrid = 1:N_PLOT_POINTS+1;
        else
            [lGetGrid, fGetGrid] = ...
                gras.geom.tri.spheretri(SPHERE_TRIANG_CONST);
        end
        lGetGrid(lGetGrid == 0) = eps;
    end
    function prepareForPlot()
        if isNewFigure
            [SData.figureNameCMat, SData.axesNameCMat] =...
                arrayfun(@(x)getSDataParams(x), (1:bodyPlotNum).',...
                'UniformOutput', false);
        end
        clrCVec = cellfun(@(x, y, z) getColor(x, y, z),...
            num2cell(colorVec, 2), ...
            num2cell(vColorVec, 2), num2cell(uColorVec),...
            'UniformOutput', false);
        [xMat,fMat] = calcBodyPoints(bodyArr,nDim,lGetGridMat, fGetGridMat);
        SData.verCMat = xMat;
        SData.xCMat = xMat;
        SData.faceCMat = fMat;
        SData.clrVec = clrCVec;
        colCMat = cellfun(@(x) getColCMat(x), clrCVec, ...
            'UniformOutput', false);
        SData.faceVertexCDataCMat = colCMat;
        
        
        function colCMat = getColCMat(clrVec)
            colCMat = clrVec(ones(1, size(xMat{1}, 2)), :);
        end
        function [figureNameCMat, axesNameCMat] = getSDataParams(iEll)
            figureNameCMat = sprintf('figure%d',iEll);
            axesNameCMat = sprintf('ax%d',iEll);
        end
        function clrVec = getColor(colorVec, vColor, uColor)
            if uColor == 1
                clrVec = vColor;
            else
                clrVec = colorVec;
            end
        end
    end
    function SData = setUpSData()
        SData.figureNameCMat=repmat({'figure'},bodyPlotNum,1);
        SData.axesNameCMat = repmat({'ax'},bodyPlotNum,1);
        SData.axesNumCMat = repmat({1},bodyPlotNum,1);
        SData.plotPatch = repmat({plotPatch},bodyPlotNum,1);
        SData.figureNumCMat = repmat({1},bodyPlotNum,1);
        
        SData.widVec = lineWidth.';
        SData.shadVec = shadVec.';
        SData.fill = (isFill)';
        SData.clrVec = colorVec;
    end
    function checkDimensions()
        import elltool.conf.Properties;
        import modgen.common.throwerror;
        ellsArrDims = dimension(bodyArr);
        mDim    = min(ellsArrDims);
        nDim    = max(ellsArrDims);
        if mDim ~= nDim
            throwerror('dimMismatch', ...
                'Objects must have the same dimensions.');
        end
        if (mDim < 1) || (nDim > 3)
            throwerror('wrongDim','object dimension can be 1, 2 or 3');
        end
        if Properties.getIsVerbose()
            if bodyPlotNum == 1
                fprintf('Plotting object...\n');
            else
                fprintf('Plotting %d objects...\n', bodyPlotNum);
            end
        end
    end
    function checkIsWrongParams()
        import modgen.common.throwerror;
        if any(lineWidth <= 0) || any(isnan(lineWidth)) || ...
                any(isinf(lineWidth))
            throwerror('wrongLineWidth', ...
                'LineWidth must be greater than 0 and finite');
        end
        if (any(shadVec < 0)) || (any(shadVec > 1)) || any(isnan(shadVec))...
                || any(isinf(shadVec))
            throwerror('wrongShade', 'Shade must be between 0 and 1');
        end
        if (any(colorVec(:) < 0)) || (any(colorVec(:) > 1)) || ...
                any(isnan(colorVec(:))) || any(isinf(colorVec(:)))
            throwerror('wrongColorVec', 'Color must be between 0 and 1');
        end
        if size(colorVec, 2) ~= 3
            throwerror('wrongColorVecSize', ...
                'ColorVec is a vector of length 3');
        end
    end
    function [colorVec, shade, lineWidth, isFill] = ...
            getPlotParams(colorVec, shade, lineWidth, isFill)
        shade = getPlotInitParam(shade, isShad, DEFAULT_SHAD);
        lineWidth = getPlotInitParam(lineWidth, ...
            isLineWidth, DEFAULT_LINE_WIDTH);
        isFill = getPlotInitParam(isFill, isIsFill, DEFAULT_FILL);
        colorVec = getColorVec(colorVec);
    end
    function outParamVec = getPlotInitParam(inParamArr, ...
            isFilledParam, multConst)
        import modgen.common.throwerror;
        if ~isFilledParam
            outParamVec = multConst*ones(1, bodyPlotNum);
        else
            nParams = numel(inParamArr);
            if nParams == 1
                outParamVec = inParamArr*ones(1, bodyPlotNum);
            else
                if nParams ~= bodyPlotNum
                    throwerror('wrongParamsNumber',...
                        'Number of params is not equal to number of objects');
                end
                outParamVec = reshape(inParamArr, 1, nParams);
            end
        end
    end
    function colorArr = getColorVec(colorArr)
        import modgen.common.throwerror;
        if ~isColorVec
            auxcolors  = hsv(bodyPlotNum);
            multiplier = 7;
            if mod(size(auxcolors, 1), multiplier) == 0
                multiplier = multiplier + 1;
            end
            colCell = arrayfun(@(x) auxcolors(mod(x*multiplier, ...
                size(auxcolors, 1)) + 1, :), 1:bodyPlotNum, 'UniformOutput',...
                false);
            colorsArr = vertcat(colCell{:});
            colorsArr = flipud(colorsArr);
            colorArr = colorsArr;
        else
            if size(colorArr, 1) ~= bodyPlotNum
                if size(colorArr, 1) ~= 1
                    throwerror('wrongColorVecSize',...
                        'Wrong size of color array');
                else
                    colorArr = repmat(colorArr, bodyPlotNum, 1);
                end
            end
        end
        
        
    end
    function checkIsWrongInput()
        import modgen.common.throwerror;
        cellfun(@(x)checkIfNoColorCharPresent(x),reg);
        cellfun(@(x)checkRightPropName(x),reg);
        
        function checkIfNoColorCharPresent(value)
            import modgen.common.throwerror;
            if ischar(value)&&(numel(value)==1)&&~isColorDef(value)
                throwerror('wrongColorChar', ...
                    'You can''t use this symbol as a color');
            end
            function isColor = isColorDef(value)
                isColor = eq(value, 'r') | eq(value, 'g') | eq(value, 'b') | ...
                    eq(value, 'y') | eq(value, 'c') | ...
                    eq(value, 'm') | eq(value, 'w');
            end
        end
        function checkRightPropName(value)
            import modgen.common.throwerror;
            if ischar(value)&&(numel(value)>1)
                if~isRightProp(value)
                    throwerror('wrongProperty', ...
                        'This property doesn''t exist');
                else
                    throwerror('wrongPropertyValue', ...
                        'There is no value for property.');
                end
            elseif ~isa(value, objClassName) && ~ischar(value)
                throwerror('wrongPropertyType', 'Property must be a string.');
            end
            function isRProp = isRightProp(value)
                isRProp = strcmpi(value, 'fill') |...
                    strcmpi(value, 'linewidth') | ...
                    strcmpi(value, 'shade') | strcmpi(value, 'color') | ...
                    strcmpi(value, 'newfigure');
            end
        end
    end
    function [ellsArr, ellNum, uColorVec, vColorVec, isCharColor] = ...
            getParams(reg)
        import modgen.common.throwerror;
        BLACK_COLOR = [0, 0, 0];
        if numel(reg) == 1
            isnLastElemCMat = {0};
        else
            isnLastElemCMat = num2cell([ones(1, numel(reg)-1), 0]);
        end
        if ischar(reg{1})
            throwerror('wrongColorChar', 'Color char can''t be the first');
        end
        isCharColor = false;
        [ellsCMat, uColorCMat, vColorCMat] = cellfun(@(x, y, z)getParams(x, y, z),...
            reg, {reg{2:end}, []}, isnLastElemCMat, 'UniformOutput', false);
        uColorVec = vertcat(uColorCMat{:});
        vColorVec = vertcat(vColorCMat{:});
        ellsArr = vertcat(ellsCMat{:});
        ellNum = numel(ellsArr);
        if ~isPlotBodies 
            plotBodies = ellNum;
        end
        uColorVec = uColorVec(1:plotBodies);
        vColorVec = vColorVec(1:plotBodies,:);
        
        function [ellVec, uColorVec, vColorVec] = getParams(ellArr, ...
                nextObjArr, isnLastElem)
            import modgen.common.throwerror;
            if isa(ellArr, objClassName)
                cnt    = numel(ellArr);
                ellVec = reshape(ellArr, cnt, 1);
                
                if isnLastElem && ischar(nextObjArr)
                    isCharColor = true;
                    colorVec1 = myColorTable(nextObjArr);
                    val = 1;
                else
                    colorVec1 = BLACK_COLOR;
                    val = 0;
                end
                uColorVec = repmat(val, cnt, 1);
                vColorVec = repmat(colorVec1, cnt, 1);
            else
                ellVec = [];
                uColorVec = [];
                vColorVec = [];
                if ischar(ellArr) && ischar(nextObjArr)
                    throwerror('wrongColorChar', ...
                        'Wrong combination of color chars');
                end
            end
        end
        function res = myColorTable(ch)
            %
            % MY_COLOR_TABLE - returns the code of the color defined by single letter.
            %
            
            if ~(ischar(ch))
                res = [0 0 0];
                return;
            end
            
            switch ch
                case 'r',
                    res = [1 0 0];
                    
                case 'g',
                    res = [0 1 0];
                    
                case 'b',
                    res = [0 0 1];
                    
                case 'y',
                    res = [1 1 0];
                    
                case 'c',
                    res = [0 1 1];
                    
                case 'm',
                    res = [1 0 1];
                    
                case 'w',
                    res = [1 1 1];
                    
                otherwise,
                    res = [0 0 0];
            end
        end
    end
end
function hVec=plotCreateFillPlotFunc(hAxes,X,faces,clrVec,isFill,...
    shade,widVec,plotPatch,varargin)
if ~isFill
    shade = 0;
end
h1 = plotPatch('Vertices',X','Faces',faces,'FaceAlpha',shade,'Parent',hAxes);
set(h1, 'EdgeColor', clrVec, 'LineWidth', widVec);
hVec = h1;
end
function figureSetPropFunc(hFigure,figureName,~)
set(hFigure,'Name',figureName);
end
function figureGroupName=figureGetGroupNameFunc(figureName)
figureGroupName=figureName;
end
function hVec=axesSetPropDoNothingFunc(hAxes,~)
hold(hAxes,'on');
hVec=[];
end
function hVec=axesSetPropDoNothing2Func(hAxes,~)
hold(hAxes,'off');
hVec=[];
end
function axesName=axesGetNameSurfFunc(name,~)
axesName=name;
end
function hVec=plotCreatePatchFunc(hAxes,vertices,faces,...
    faceVertexCData,faceAlpha,clrVec)
import modgen.graphics.camlight;
LIGHT_TYPE_LIST={{'left'},{40,-65},{-20,25}};
hVec = patch('Vertices',vertices', 'Faces', faces, ...
    'FaceVertexCData', faceVertexCData, 'FaceColor','flat', ...
    'FaceAlpha', faceAlpha,'EdgeColor',clrVec,'Parent',hAxes);
hLightVec=cellfun(@(x)camlight(hAxes,x{:}),LIGHT_TYPE_LIST);
hVec=[hVec,hLightVec];
shading(hAxes,'interp');
lighting(hAxes,'phong');
material(hAxes,'metal');
view(hAxes,3);
end