classdef ReachContLTIProblemDef<gras.ellapx.lreachuncert.probdef.AReachContProblemDef
    methods(Static,Access=protected)
        function isOk=isPartialCompatible(aCMat,bCMat,pCMat,pCVec,cCMat,...
                qCMat,qCVec,x0Mat,x0Vec,tLims)
            import gras.sym.isdependent;
            isOk = ...
                isdependent(aCMat)&&...
                isdependent(bCMat)&&...
                isdependent(pCMat)&&...
                isdependent(pCVec)&&...
                isdependent(cCMat)&&...
                isdependent(qCMat)&&...
                isdependent(qCVec);
        end
    end     
    methods(Static)
        function isOk=isCompatible(aCMat,bCMat,pCMat,pCVec,cCMat,...
                qCMat,qCVec,x0Mat,x0Vec,tLims)
            isOk = ...
                gras.ellapx.lreachuncert.probdef.ReachContLTIProblemDef.isPartialCompatible(...
                aCMat,bCMat,pCMat,pCVec,cCMat,qCMat,qCVec,x0Mat,x0Vec,tLims)&&...
                gras.ellapx.lreachuncert.probdef.AReachContProblemDef.isCompatible(...
                aCMat,bCMat,pCMat,pCVec,cCMat,qCMat,qCVec,x0Mat,x0Vec,tLims);
        end
    end
    methods
        function self=ReachContLTIProblemDef(aCMat,bCMat,pCMat,pCVec,...
                cCMat,qCMat,qCVec,x0Mat,x0Vec,tLims)
            %
            import gras.ellapx.lreachuncert.probdef.ReachContLTIProblemDef;
            %
            if ~ReachContLTIProblemDef.isPartialCompatible(aCMat,bCMat,pCMat,...
                    pCVec,cCMat,qCMat,qCVec,x0Mat,x0Vec,tLims)
                modgen.common.throwerror(...
                    'wrongInput', 'Incorrect system definition');
            end
            %
            self=self@gras.ellapx.lreachuncert.probdef.AReachContProblemDef(...
                aCMat,bCMat,pCMat,pCVec,cCMat,qCMat,qCVec,x0Mat,x0Vec,...
                tLims);
        end
    end
end