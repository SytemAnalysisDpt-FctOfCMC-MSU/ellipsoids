classdef ContSingleTubeControl
    %
    properties (Access = private)
        properEllTube
        probDynamicsList
        goodDirSetList
        downScaleKoeff
        controlVectorFunct
        switchSysTimeVec
    end
    %
    methods
        function self = ContSingleTubeControl(properEllTube,...
                probDynamicsList, goodDirSetList, switchSysTimeVec,...
                inDownScaleKoeff)
            % CONTSINGLETUBECONTROL constructes an object for 
            % control synthesis for a continuous time system based on a
            % single ellipsoidal tube from any predetermined position 
            % (t,x) and corresponding trajectory
            %
            % Input:
            %   regular:
            %       properEllTube: gras.ellapx.smartdb.rels.EllTube[1,1]
            %           - an object containing ellipsoidal tube that is
            %           used for contol synthesis constructing
            %
            %       probDynamicsList:  
            %           gras.ellapx.lreachplain.probdyn.LReachProblemLTIDynamics[1,]
            %           - cellArray providing information about system's
            %           dynamics 
            %
            %       goodDirSetList: 
            %           gras.ellapx.lreachplain.GoodDirsContinuousLTI[1,]
            %           - cellArray provides information about
            %           'good directions'
            %
            %       switchSysTimeVec: double[1,] - system switch time
            %           moments vector
            %
            %       inDownScaleKoeff: double[1,1] - scaling coefficient for
            %           internal ellipsoid tube approximation
            %
            % $Author: Komarov Yuri <ykomarov94@gmail.com> $ 
            % $Date: 2015-30-10 $
            %           
            self.properEllTube = properEllTube;
            self.probDynamicsList = probDynamicsList;
            self.goodDirSetList = goodDirSetList;
            self.switchSysTimeVec = switchSysTimeVec;
            self.downScaleKoeff = inDownScaleKoeff;
            self.controlVectorFunct = ...
                elltool.control.ControlVectorFunct(properEllTube, ...
                self.probDynamicsList, self.goodDirSetList, ...
                inDownScaleKoeff);
        end


        function [trajEvalTime, trajectory] = ...
                    getTrajectory(self,x0Vec)
            % GETTRAJECTORY returns a trajectory corresponding
            % to constructed control synthesis 
            % 
            % Input:
            %   regular:
            %       x0Vec: double[nDims,1], where nDims is 
            %           a dimentionality of phase space - position 
            %           the syntesis is to be constructed from
            %
            % Output:
            %   trajectoryMat - double[n,] where n is a dimentionality
            %       of the phase space - trajectory, that corresponds
            %       to constructed control synthesis
            %
            % $Author: Komarov Yuri <ykomarov94@gmail.com> $ 
            % $Date: 2015-30-10 $
            %
            import modgen.common.throwerror;
            ERR_TOL = 1e-4;
            REL_TOL = elltool.conf.Properties.getRelTol();
            ABS_TOL = elltool.conf.Properties.getAbsTol();
            trajectory = [];
            trajEvalTime = [];
            switchTimeVecLenght = length(self.switchSysTimeVec);
            SOptions = odeset('RelTol',REL_TOL,'AbsTol',ABS_TOL);
            self.properEllTube.scale(@(x)1/sqrt(self.downScaleKoeff),...
                'QArray'); 
            %
            q0Vec = self.properEllTube.aMat{1}(:,1);
            q0Mat = self.properEllTube.QArray{1}(:,:,1);
            isX0inSet = dot(x0Vec-q0Vec,q0Mat\(x0Vec-q0Vec));
            %
            for iSwitch = 1:switchTimeVecLenght-1                 
                iSwitchBack = switchTimeVecLenght - iSwitch;
                %
                tStart = self.switchSysTimeVec(iSwitch);
                tFin = self.switchSysTimeVec(iSwitch+1);
                %
                indFin = find(self.properEllTube.timeVec{1} == tFin);
                AtMat = self.probDynamicsList{iSwitchBack}.getAtDynamics();
                %
                [curTrajEvalTime,odeResMat] = ode45(@(t,y)ode(t,y,AtMat,...
                    self.controlVectorFunct,tFin,tStart),[tStart tFin],...
                    x0Vec.',SOptions);
                %
                q1Vec = self.properEllTube.aMat{1}(:,indFin);
                q1Mat = self.properEllTube.QArray{1}(:,:,indFin);
                %
                currentScalProd = dot(odeResMat(end,:).'-q1Vec,...
                    q1Mat\(odeResMat(end,:).'-q1Vec));
                %
                if (isX0inSet)&&(currentScalProd > 1 + ERR_TOL)
                    throwerror('TestFails', ['the result of test does '...
                        'not correspond with theory, current scalar ' ...
                        'production at the end of system switch ' ...
                        'interval number ', num2str(iSwitchBack), ' is '...
                        num2str(currentScalProd), ', while the original'...
                        ' solvability domain actually contains x(t0)']);
                end
                %
                x0Vec = odeResMat(end,:);
                trajectory = vertcat(trajectory,odeResMat);
                trajEvalTime = vertcat(trajEvalTime,curTrajEvalTime);
            end
            %
            function dyMat = ode(time,yMat,AtMat,controlFuncVec, ...
                    tFin,tStart)
               dyMat = -AtMat.evaluate(tFin-time+tStart)*yMat +...
                   controlFuncVec.evaluate(yMat,time);
            end            
        end
        %
        function controlFunc = getControlFunction(self)
            % GETCONTROLFUNCTION returns controlVectorFunct class's
            % property
            %
            % Output:
            %   controlFunc: elltool.control.ControlVectorFunct[1,1]
            %       - an object providing evaluation of control
            %       synthesis for predetermined position (t,x)
            %
            controlFunc = self.controlVectorFunct.clone();
        end
        %
        function properEllTube = getProperEllTube(self)
            % GETPROPERELLTUBE returns copy of properEllTube class's
            % property
            %
            % Output:
            %       properEllTube: gras.ellapx.smartdb.rels.EllTube[1,1]
            %           - an object containing ellipsoidal tube that is
            %           used for contol synthesis constructing
            %
            %
            properEllTube = self.properEllTube.clone();
        end
    end
end