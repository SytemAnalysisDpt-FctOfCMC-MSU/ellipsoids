classdef ConstArrayFunction<gras.mat.AMatrixFunctionComparable
    properties (Access=protected)
        mArray
        mSizeVec
        nDims
        nRows
        nCols
    end
    methods
        function mSizeVec = getMatrixSize(self)
            mSizeVec = self.mSizeVec;
        end
        function res=evaluate(self,timeVec)
            res = self.mArray;
        end
        function nDims=getDimensionality(self)
            nDims = self.nDims;
        end
        function nCols=getNCols(self)
            nCols = self.nCols;
        end
        function nRows=getNRows(self)
            nRows = self.nRows;
        end
    end
    methods
        function self=ConstArrayFunction(mArray)
            %
            modgen.common.type.simple.checkgen(mArray,...
                'isnumeric(x)&&~isempty(x)');
            %
            sizeArray = size(mArray);
            self.mArray = mArray;
            self.mSizeVec = sizeArray(1:2);
            self.nRows = self.mSizeVec(1);
            self.nCols = self.mSizeVec(2);
        end
    end
    methods (Access=protected)
        function [SDataArr, SFieldNiceNames, SFieldDescr] = toStructInternal(self,isPropIncluded)
            if (nargin < 2)
                isPropIncluded = false;
            end
            
            SEll = struct('mArray', ConstArray);
            if isPropIncluded
                SEll.absTol = ConstArray.getAbsTol();
                SEll.relTol = ConstArray.getRelTol();
            end
            
            SDataArr = SEll;
            SFieldNiceNames = struct('mArray','mAr');
            SFieldDescr = struct('mArray','mArray');
            
            if isPropIncluded
                SFieldNiceNames.absTol = 'absTol';
                SFieldNiceNames.relTol = 'relTol';
                
                SFieldDescr.absTol = 'Absolute tolerance.';
                SFieldDescr.relTol = 'Relative tolerance.';
            end
            
        end
    end
end