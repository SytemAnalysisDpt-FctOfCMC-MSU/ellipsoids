function [tout,yout,dyRegMat,interpObj] = ode45reg(fOdeDeriv,fOdeReg,tspan,y0,...
    options,varargin)
% ODE45REG is an extension of built-in ode45 solver capable of solving ODEs
% with right hand-side functions having a limited definition area
%
% Input:
%   regular:
%       fOdeDeriv: function_handle[1,1] - function responsible for
%           calculating the right-hand side function as f=fOdeDeriv(t,y)
%       fOdeReg: function_handle[1,1] - function responsible for
%           regularizing the phase variables as
%           [isStrictViolation,yReg]=fOdeReg(t,y) where isStrictViolation
%           is supposed to be true when y is outside of definition area of
%           the right-hand side function
%       tspan: double[1,2]/double[1,nPoints] time range, same meaning 
%           as in ode45
%       y0: double[1,nDims] - initial state, same meaning as in ode45
%       
%   optional:
%       options: odeset[1,1] - options generated by odeset function, same
%           meaning as in ode45
%
%   properties:
%       regMaxStepTol: double[1,1] - maximum allowed regularization size
%           calculated as max(abs(yReg-y)) allowed per step
%       regAbsTol: double[1,1] - maximum regularization tolerance
%           calculated as max(abs(yReg-y)) that is allowed to consider the
%           integration step to be successful. If the tolerance level is
%           not achieved the regularization continues in the iterative
%           manner via correcting dyReg or decreasing the step size
%       nMaxRegSteps: double[1,1] - maximum number of allowed
%           regularization steps, if regAbsTol is not achieved in 
%           nMaxRegSteps(or less) the integration process fails
%
% Output:
%   tout: double[nPoints,1] - time grid, same meaning as in ode45
%   yout: double[nPoints,nDims] - solution, same meaning as in ode45
%   dyRegMat: double[nPoints,nDims] - regularizing derivative addition
%       to the right-hand side function value performed at each step,
%       basically yout is a solution of dot(y)=fOdeDeriv(t,y)+dyRegMat(t,y)
%
% $Author: Peter Gagarinov  <pgagarinov@gmail.com> $	$Date: 2011$
% $Copyright: Moscow State University,
%            Faculty of Computational Mathematics and Computer Science,
%            System Analysis Department 2011 $
%
import modgen.common.throwerror;
import modgen.common.type.simple.*;
solver_name = 'ode45reg';

%% ���� ���� ����������
if nargout == 4
    interpObj =  gras.ode.VecOde45RegInterp(fOdeReg);
end



%% Constants
N_MAX_REG_STEPS_DEFAULT=3;
N_PROGRESS_DOTS_SHOWN=10;
%% Check inputs
if nargin < 4
    options = [];
    if nargin < 3
        throwerror('wrongInput','not enough input arguments');
    end
end
[opts,~,regMaxStepTol,regAbsTol,nMaxRegSteps,isRegMaxStepTolSpec,...
    isRegAbsTolSpec]=modgen.common.parseparext(varargin,...
    {'regMaxStepTol','regAbsTol','nMaxRegSteps';...
    [],[],N_MAX_REG_STEPS_DEFAULT;...
    'isnumeric(x)','isnumeric(x)','isnumeric(x)'});
options=odeset(options,opts{:});
%% Stats
nsteps  = 0;
nfailed = 0;
nfevals = 0;
%
%% There might be no output requested...
checkgen(fOdeDeriv,'isfunction(x)');
checkgen(fOdeReg,'isfunction(x)');
%
%% Handle solver arguments
[neq, tspan, ntspan, next, t0, tfinal, y0, f0, ...
    options, threshold, rtol, normcontrol, normy, hmax, htry, htspan,...
    dataType,absTol] = ...
    odearguments(solver_name,fOdeDeriv, tspan, y0, options);

if nargout == 4
    interpObj.dataType = dataType;
    interpObj.neq = neq;
    interpObj.t0 = t0;
    interpObj.y0 = y0;
    interpObj.next = next;
    interpObj.tfinal = tfinal;
end;

if ~isRegMaxStepTolSpec
    regMaxStepTol=absTol*10;
end
if ~isRegAbsTolSpec
    regAbsTol=256*eps(dataType);
end
nfevals = nfevals + 1;
prDispObj=gras.gen.ProgressCmdDisplayer(t0,tfinal,...
    N_PROGRESS_DOTS_SHOWN,modgen.common.getcallername());
prDispObj.start();
%% Handle the output
refine = max(1,odeget(options,'Refine',4,'fast'));
if ntspan > 2
    outputAt = 'RequestedPoints';         % output only at tspan points
elseif refine <= 1
    outputAt = 'SolverSteps';             % computed points, no refinement
else
    outputAt = 'RefinedSteps';            % computed points, with refinement
    S = (1:refine-1) / refine;
end
%
t = t0;
y = y0;

%% Allocate memory for the output.
if ntspan > 2                         % output only at tspan points
    tout = zeros(1,ntspan,dataType);
    yout = zeros(neq,ntspan,dataType);
    dyRegMat=yout;
else                                  % alloc in chunks
    chunk = min(max(100,50*refine), refine+floor((2^13)/neq));
    tout = zeros(1,chunk,dataType);
    yout = zeros(neq,chunk,dataType);
    dyRegMat=yout;
end
nout = 1;
tout(nout) = t;
yout(:,nout) = y;

%% Initialize method parameters.
pow = 1/5;
A = [1/5, 3/10, 4/5, 8/9, 1, 1];
B = [
    1/5         3/40    44/45   19372/6561      9017/3168       35/384
    0           9/40    -56/15  -25360/2187     -355/33         0
    0           0       32/9    64448/6561      46732/5247      500/1113
    0           0       0       -212/729        49/176          125/192
    0           0       0       0               -5103/18656     -2187/6784
    0           0       0       0               0               11/84
    0           0       0       0               0               0
    ];
E = [71/57600; 0; -71/16695; 71/1920; -17253/339200; 22/525; -1/40];
f = zeros(neq,7,dataType);
hmin = 16*eps(t);
if isempty(htry)
    % Compute an initial step size h using y'(t).
    absh = min(hmax, htspan);
    if normcontrol
        rh = (norm(f0) / max(normy,threshold)) / (0.8 * rtol^pow);
    else
        rh = norm(f0 ./ max(abs(y),threshold),inf) / (0.8 * rtol^pow);
    end
    if absh * rh > 1
        absh = 1 / rh;
    end
    absh = max(absh, hmin);
else
    absh = min(hmax, max(hmin, htry));
end
f(:,1) = f0;
dyCurCorrVec=zeros(neq,1);
%% THE MAIN LOOP
isDone = false;
while ~isDone
    
    %% By default, hmin is a small number such that t+hmin is only slightly
    %% different than t.  It might be 0 if t is 0.
    hmin = 16*eps(t);
    absh = min(hmax, max(hmin, absh));    % couldn't limit absh until new hmin
    h = absh;
    
    %% Stretch the step if within 10% of tfinal-t.
    if 1.1*absh >= abs(tfinal - t)
        h = tfinal - t;
        absh = abs(h);
        isDone = true;
    end
    
    %% LOOP FOR ADVANCING ONE STEP.
    isNeverFailed = true;    
    iRegStep=0;
    dyNewCorrVec=zeros(neq,1,dataType);
    % no failed attempts
    while true
        prDispObj.progress(t);
        if iRegStep==0
            dyCurCorrVec=zeros(neq,1,dataType);
        end
        isRejectedStep=false;
        hA = h * A;
        hB = h * B;
        f(:,1)=f(:,1)+dyCurCorrVec;
        for iStep=1:5
            yInterimNewVec=y+f*hB(:,iStep);
            tStep=t+hA(iStep);
            [isStrictViol,yInterimNewRegVec]=fOdeReg(tStep,yInterimNewVec);
            yCurCorrVec=(yInterimNewRegVec-yInterimNewVec);
            errReg = 2*max(abs(yCurCorrVec))/...
                (max(abs(yInterimNewRegVec))+max(abs(yInterimNewVec)));
            isWeakViol=errReg>=regAbsTol;
            if isStrictViol
                isRejectedStep=true;
                break
            elseif isWeakViol
                if errReg>regMaxStepTol
                    isRejectedStep = true;
                    break;
                end                
            end
            f(:,iStep+1) = feval(fOdeDeriv,tStep,yInterimNewVec)+...
                dyNewCorrVec;
        end
        %
        if ~isRejectedStep
            tnew = t + hA(6);
            if isDone
                tnew = tfinal;   % Hit end point exactly.
            end
            h = tnew - t;      % Purify h.
            
            ynew = y + f*hB(:,6);
            %
            [isStrictViol,yNewRegVec]=fOdeReg(tnew,ynew);
            yCurCorrVec=(yNewRegVec-ynew);
            errReg =2*max(abs(yCurCorrVec))/(max(abs(yNewRegVec))+max(abs(ynew)));
            isWeakViol=errReg>regAbsTol;
            if (iRegStep>nMaxRegSteps)&&isWeakViol
                throwerror('wrongState',...
                    ['Oops, we shouldn''t be here, regularization ',...
                    'haven''t worked after %d steps'],iRegStep);
            end
            % Estimate the error.
            if isStrictViol
                isRejectedStep=true;
            else
                f(:,7) = feval(fOdeDeriv,tnew,ynew)+dyNewCorrVec;
                nfevals = nfevals + 6;                
                if normcontrol
                    normynew = norm(ynew);
                    errwt = max(max(normy,normynew),threshold);
                    err = absh * (norm(f * E) / errwt);
                else
                    err = absh * norm((f * E) ./ max(max(abs(y),abs(ynew)),threshold),inf);
                end
                if isWeakViol
                    if errReg>regMaxStepTol
                        isRejectedStep = true;
                    end
                    dyCurCorrVec=yCurCorrVec./h;                    
                end
            end
        end
        
        % Accept the solution only if the weighted error is no more than the
        % tolerance rtol.  Estimate an h that will yield an error of rtol on
        % the next step or the next try at taking this step, as the case may be,
        % and use 0.8 of this value to avoid failures.
        isFailedStep=isRejectedStep||(err>rtol);
        if isFailedStep      
            if iRegStep>0
                throwerror('wrongState',...
                    ['Oops, we shouldn''t be here, regularization ',...
                    'haven''t worked']);
            end
            % Failed step
            nfailed = nfailed + 1;
            if absh <= hmin
                msg=message('MATLAB:ode45:IntegrationTolNotMet', ...
                    sprintf( '%e', t ), sprintf( '%e', hmin ));
                if isRejectedStep
                    error(msg);
                else
                    warning(msg);
                    shrinkResults();
                    prDispObj.finish();
                    return;
                end
            end
            %
            if isNeverFailed
                isNeverFailed = false;
                if isRejectedStep
                    absh = max(hmin, 0.5*absh);
                else
                    absh = max(hmin, absh * max(0.1, 0.8*(rtol/err)^pow));
                end
            else
                absh = max(hmin, 0.5 * absh);
            end
            h = absh;
            isDone = false;
        else
            if isWeakViol
                iRegStep=iRegStep+1;
                dyNewCorrVec=dyNewCorrVec+dyCurCorrVec;
            else
                % Successful step
                %dyNewCorrVec=dyCurCorrVec;
                ynew=yNewRegVec;
                break;
            end
        end
    end
    nsteps = nsteps + 1;
    switch outputAt
        case 'SolverSteps'        % computed points, no refinement
            nout_new = 1;
            tout_new = tnew;
            yout_new = ynew;
        case 'RefinedSteps'       % computed points, with refinement
            tref = t + (tnew-t)*S;
            nout_new = refine;
            tout_new = [tref, tnew];
            yout_new = [ntrp45(tref,t,y,h,f,fOdeReg), ynew];
        case 'RequestedPoints'    % output only at tspan points
            nout_new =  0;
            tout_new = [];
            yout_new = [];
            
            if nargout == 4
                interpObj.tnewVec = [interpObj.tnewVec tnew];
                interpObj.ynewCVec = [interpObj.ynewCVec {ynew}];
                interpObj.tCVec = [interpObj.tCVec {t}];
                interpObj.yCVec = [interpObj.yCVec {y}];
                interpObj.hCVec = [interpObj.hCVec {h}];
                interpObj.fCVec = [interpObj.fCVec {f}];
                interpObj.dyNewCorrVec = [interpObj.dyNewCorrVec {dyNewCorrVec}];
            end;
            
            while next <= ntspan
                if tnew < tspan(next)
                    break;
                end
                nout_new = nout_new + 1;
                tout_new = [tout_new, tspan(next)];
                if tspan(next) == tnew
                    yout_new = [yout_new, ynew];
                else
                    yout_new = [yout_new, ntrp45(tspan(next),t,y,h,f,fOdeReg)];
                end
                next = next + 1;
            end
    end
    if nout_new > 0
        oldnout = nout;
        nout = nout + nout_new;
        if nout > length(tout)
            tout = [tout, zeros(1,chunk,dataType)];  % requires chunk >= refine
            yout = [yout, zeros(neq,chunk,dataType)];
        end
        idx = oldnout+1:nout;
        tout(idx) = tout_new;
        yout(:,idx) = yout_new;
        dyRegMat(:,idx)=repmat(dyNewCorrVec,1,nout_new);
    end
    
    if isDone
        break
    end
    
    %% If there were no failures compute a new h.
    if isNeverFailed&&(iRegStep<0.5*nMaxRegSteps)
        % Note that absh may shrink by 0.8, and that err may be 0.
        temp = 1.25*(err/rtol)^pow;
        if temp > 0.2
            absh = absh / temp;
        else
            absh = 5.0*absh;
        end
    end
    
    %% Advance the integration one step.
    t = tnew;
    y = ynew;
    if normcontrol
        normy = normynew;
    end
    f(:,1) = f(:,7)-dyNewCorrVec;
    % remove regularization and it will be independently 
    % applied on the next step
    % Already have f(tnew,ynew)
    
end
if nargout == 4
    interpObj.oldnout = nout;
end;
shrinkResults();
prDispObj.finish();
    function shrinkResults()
        tout = tout(1:nout).';
        yout = yout(:,1:nout).';
        dyRegMat = dyRegMat(:,1:nout).';
    end
end
function yinterp = ntrp45(tinterp,t,y,h,f,fOdeReg)
BI = [
    1       -183/64      37/12       -145/128
    0          0           0            0
    0       1500/371    -1000/159    1000/371
    0       -125/32       125/12     -375/64 
    0       9477/3392   -729/106    25515/6784
    0        -11/7        11/3        -55/28
    0         3/2         -4            5/2
    ];
s = (tinterp - t)/h;  
[~,yinterp] = fOdeReg(tinterp,y(:,ones(size(tinterp)))+...
    f*(h*BI)*cumprod([s;s;s;s]));
end