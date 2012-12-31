function  [SData,plObj,bodyArr,bodyNum,uColorVec,vColorVec,...
    colorVec,nDim,isNewFigure] = plotPrepareGeomBodyArr(objClassName,varargin)


import modgen.common.throwerror;
DEFAULT_LINE_WIDTH = 1;
DEFAULT_SHAD = 0.4;
DEFAULT_FILL = false;
[reg,~,plObj,isNewFigure,isFill,lineWidth,colorVec,shadVec,...
    isRelPlotterSpec,~,isIsFill,isLineWidth,isColorVec,isShad]=...
    modgen.common.parseparext(varargin,...
    {'relDataPlotter','newFigure','fill','lineWidth','color','shade' ;...
    [],0,[],[],[],0;@(x)isa(x,'smartdb.disp.RelationDataPlotter'),...
    @(x)isa(x,'logical'),@(x)isa(x,'logical'),@(x)isa(x,'double'),...
    @(x)isa(x,'double'),...
    @(x)isa(x,'double')});
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
nDim = max(dimension(bodyArr));
if nDim == 3 && isLineWidth
    throwerror('wrongProperty', 'LineWidth is not supported by 3D Ellipsoids');
end
[colorVec, shadVec, lineWidth, isFill] = getPlotParams(colorVec, shadVec,...
    lineWidth, isFill);
checkIsWrongParams();
checkDimensions();
SData = setUpSData();
    

    function SData = setUpSData()
        SData.figureNameCMat=repmat({'figure'},bodyNum,1);
        SData.axesNameCMat = repmat({'ax'},bodyNum,1);
        SData.axesNumCMat = repmat({1},bodyNum,1);
        
        SData.figureNumCMat = repmat({1},bodyNum,1);
        
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
                'Ellipsoids must have the same dimensions.');
        end
        if (mDim < 1) || (nDim > 3)
            throwerror('wrongDim','ellipsoid dimension can be 1, 2 or 3');
        end
        if Properties.getIsVerbose()
            if bodyNum == 1
                fprintf('Plotting ellipsoid...\n');
            else
                fprintf('Plotting %d ellipsoids...\n', bodyNum);
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
            outParamVec = multConst*ones(1, bodyNum);
        else
            nParams = numel(inParamArr);
            if nParams == 1
                outParamVec = inParamArr*ones(1, bodyNum);
            else
                if nParams ~= bodyNum
                    throwerror('wrongParamsNumber',...
                        'Number of params is not equal to number of ellipsoids');
                end
                outParamVec = reshape(inParamArr, 1, nParams);
            end
        end
    end
    function colorArr = getColorVec(colorArr)
        import modgen.common.throwerror;
        if ~isColorVec
            auxcolors  = hsv(bodyNum);
            multiplier = 7;
            if mod(size(auxcolors, 1), multiplier) == 0
                multiplier = multiplier + 1;
            end
            colCell = arrayfun(@(x) auxcolors(mod(x*multiplier, ...
                size(auxcolors, 1)) + 1, :), 1:bodyNum, 'UniformOutput',...
                false);
            colorsArr = vertcat(colCell{:});
            colorsArr = flipud(colorsArr);
            colorArr = colorsArr;
        else
            if size(colorArr, 1) ~= bodyNum
                if size(colorArr, 1) ~= 1
                    throwerror('wrongColorVecSize',...
                        'Wrong size of color array');
                else
                    colorArr = repmat(colorArr, bodyNum, 1);
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