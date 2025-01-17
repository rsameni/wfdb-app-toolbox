function varargout=corrint(varargin)
%
% [y1,y2,y3]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode,findScaling)
%
% Correlation integral analysis of a time series. Based on:
%
% [1] Kaplan, Daniel, and Leon Glass. Understanding nonlinear dynamics. Vol. 19. Springer, 1995.
% [2] Kantz, Holger, and Thomas Schreiber. Nonlinear time series analysis. Cambridge university press, 2004.
%
% Required input parameter:
% x
%       Nx1 matrix (doubles) of time series to be analyzed.
%
% Optional Parameters are:
%
% embeddedDim
%        1x1 Integer specifying the embedded dimension size to use (default
%        =2).
%
% timeLag
%       1x1 Integer specifying the minimum time lag distance (in samples) of the point to
%       be estimated. Default is 2. If timeLag=-1 the timeLag is estimated
%       from the first zero-crossing point of the autocorrelation of x.
%
% timeStep
%       1x1 Integer specifying time lag distance (in samples) within
%       each point used in the embeddedDimm vector. For example, if embeddedDim
%       is 3 and timeStep =2, then the embedded dimension vector will consists of
%       3 samples separated by 2 samples each, covering a window of size of 7 samples.
%
% distanceThreshold
%       1x1 double specifying the distance threshold between embedded
%       points. The points who's distance is less than distanceThreshold are considered in
%       the same neighborhood and used for either prediction, recurrence, or the
%       estimation of the embedded dimension.
%
% neighboorSize
%      1x1 Integer specifying the number of neighbors to be used for
%      prediction and smoothing (see 'estimationMode' parameter).
%
% estimationMode
%       String specifying what analysis type to be done in the time series.
%       Options are:
%                       'recurrence'  -Calculates recurrence data to be used
%                                      in for recurrence plots (default).
%                       'dimension'   -Generates statistics for the estimation of the correlation dimension
%                                      of the time series and it's scaling
%                                      regions.
%                       'prediction'  -Predicts second half of the time
%                                      series using the first half as a model
%                                      and neighboorSize nearest points.
%                       'smooth'      -Predicts all point of the times
%                                      series using all other points as a
%                                      model and neighboorSize nearest
%                                      points.
%
% findScaling
%      1x1 Boolean flag to be passed when using 'dimension' mode. If set to
%      true, the scaling region will be searched automatically, using
%      r1=std(x)/4 and r2 -> C(r1)/C(r2) ~ 5. Default value is false.
%
% The output returned by CORRINT is dependent on the 'estimationMode'
% parameter, so that the description of the output below is broken down into the
% different possible options for the 'estimationMode' parameter.
%
% Output Parameters - 'recurrence' mode
% y1 
%		Lx1 Vector of integers for state i.
% y2 
%		Lx1 Vector of integers for state state j that is a neighbor of state i (first column).
%
% Output Parameters - 'dimension' mode
% y1 
%		Lx1 Vector of doubles of log(distanceThreshold). 
% y2 
%		Lx1 Vector of doubles for log(neighborhood size) given the distanceThreshold used in column 1.
% y3
%       1x1 double. Optional, estimated slope of y1 and y2 
%
% Output Parameters - 'prediction' mode
% y1 
%		Lx1 Vector of doubles of estimated second half of the time series. 
% y2 
%		Lx1 Vector of doubles for original second half of the time series.
% y3
%       1x1 double. Optional, variance of the prediction error divided by variance of the second half of the time series. 
%
%
% Output Parameters - 'smooth' mode
% y1 
%		Lx1 Vector of doubles of smoothed the time series. 
% y2 
%		Lx1 Vector of doubles for original time series.
% y3
%       1x1 double. Optional, variance of the prediction error divided by variance of the time series. 
%
%
% %%% Beging Example %%%
% 
% N=500; %Number of points for each process
% model_names={'linearModel','nonlinearModel'};
% 
% %Linear Auto Regressive model with measurement noise
% linearModel=zeros(N,1);
% x=77;
% linearModel(1)=x;
% for n=2:N
%     x=4 + 0.95*x;
%     linearModel(n)= x + randn(1)*2;
% end
% 
% %Non-linear model of dimension ~ 3.9
% nonlinearModel=zeros(N,1);
% x=0.2;y=0.2;z=0.2;v=0.2;model_five(1)=x;
% for n=2:N
%     m=0.4 - 6/(1+ x^2 + y^2);
%     xold=x;yold=y;zold=z;vold=v;
%     x= 1 + 0.7*(xold*cos(m)-yold*sin(m)) + 0.2*zold;
%     y=0.7*(xold*sin(m) + yold*cos(m));
%     z=1.4 + 0.3*vold - zold^2;
%     v=zold;
%     nonlinearModel(n)= x + 0.3*z + randn(1)*0.05;
% end
% 
% %Plot time series
% figure(1)
% for i=1:2
%     subplot(2,1,i)
%     eval(['plot(' model_names{i} ');legend(''' model_names{i} ''')'])
%     title('Time Plot');xlabel('time')
% end
% 
% %Plot cross correlation
% figure(2)
% for i=1:2
%     subplot(2,1,i)
%     eval(['x=' model_names{i} ';'])
%     R=xcorr(x-mean(x),'coeff');
%     plot(R(round(N):end))
%     eval(['legend(''' model_names{i} ''')'])
%     title('Autocorelation'); xlabel('lag')
% end
% 
% %Plot Phase Plots
% figure(3)
% for i=1:2
%     subplot(2,1,i)
%     eval(['x=' model_names{i} ';'])
%     scatter(x(1:end-1),x(2:end))
%     eval(['legend(''' model_names{i} ''')'])
%     title('Phase Plot');xlabel('x(t)');ylabel('x(t+1)')
% end
% 
% %Plot prediction errors vs surrogate 
% timeLag=1;
% timeStep=1;
% distanceThreshold=[];
% embeddedDim=4;
% estimationMode='smooth';
% figure(4)
% K=[1:20 25 30 50 70 100];
% D=length(K);
% surrN=10;
% for i=1:2
%     eval(['x=' model_names{i} ';'])
%     err=zeros(D,1)+NaN;
%     surr_data=zeros(D,surrN);
%     SURR=surrogate(x,surrN);
%     for d=1:D;
%         neighboorSize=K(d);
%         [y1,y2,y3]=corrint(x,embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
%         err(d)=y3;
%         for s=1:surrN
%             [y1,y2,y3]=corrint(SURR(:,s),embeddedDim,timeLag,timeStep,distanceThreshold,neighboorSize,estimationMode);
%             surr_data(d,s)=y3;
%         end
%     end
%     subplot(2,1,i)
%     plot(K,err,'o-');hold on
%     errorbar(K,mean(surr_data,2),var(surr_data,[],2)./sqrt(10),'r')
%     eval(['legend(''' model_names{i} ''',''surrogate'')'])
%     xlabel('Embedded Dimension')
%     ylabel('err/var')
%     
% end
%
% %%% End Example %%%
%
% Written by Ikaro Silva, 20134
% Last Modified: November 23, 2014
% Version 1.0
%
% Since 0.9.8
%
%
% See also SURROGATE, DFA, MSENTROPY

%endOfHelp

[javaWfdbExec,config]=getWfdbClass('corrint');

%Set default pararamter values
inputs={'x','embeddedDim','timeLag','timeStep','distanceThreshold','neighboorSize','estimationMode','findScaling'};
outputs={'y1','y2','y3'};
embeddedDim=[];
timeLag=[];
timeStep=[];
distanceThreshold=[];
neighboorSize=[];
estimationMode='recurrence';
findScaling=0;
wfdb_argument={};
y1=[];
y2=[];
y3=[];
for n=1:nargin
    if(~isempty(varargin{n}))
        eval([inputs{n} '=varargin{n};'])
    end
end
if(~isempty(embeddedDim))
    wfdb_argument{end+1}='-d';
    wfdb_argument{end+1}=num2str(embeddedDim);
end
if(~isempty(timeLag))
    wfdb_argument{end+1}='-t';
    wfdb_argument{end+1}=num2str(timeLag);
end
if(~isempty(timeStep))
    wfdb_argument{end+1}='-s';
    wfdb_argument{end+1}=num2str(timeStep);
end
if(~isempty(distanceThreshold))
    wfdb_argument{end+1}='-r';
    wfdb_argument{end+1}=num2str(distanceThreshold);
end
if(~isempty(neighboorSize))
    wfdb_argument{end+1}='-n';
    wfdb_argument{end+1}=num2str(neighboorSize);
end

switch estimationMode
    case 'recurrence'
        wfdb_argument{end+1}='-p';
    case 'dimension'
        wfdb_argument{end+1}='-v';
        y3=' ';
        if(findScaling)
            wfdb_argument{end+1}='-a';
        end
    case 'prediction'
        wfdb_argument{end+1}='-P';
    case 'smooth'
        wfdb_argument{end+1}='-S';
        y3=' ';
    otherwise
        error(['Unkown estimation mode: ' estimationMode])
end

javaWfdbExec.setArguments(wfdb_argument);

if(config.inOctave)
    x=cellstr(num2str(x));
    x=javaWfdbExec.execWithStandardInput(x);
    Nx=x.size;
    out=cell(Nx,1);
    for n=1:Nx
        out{n}=x.get(n-1);
    end
else
    out=cell(javaWfdbExec.execWithStandardInput(x).toArray);
end
M=length(out);
if(~isempty(y3))
    y3=out{end};
    out(end)=[];
    M=M-1;
    if(strcmp(estimationMode,'smooth'))
        tmp=y3;
        sep=regexp(tmp,'\s');
        y3=str2num(tmp(sep(end):end));
    end
end
if(~isempty(strfind(out{1},'Possibly')))
    warning(out{1})
    out(1)=[];
    M=M-1;
end

y1=zeros(M,1)+NaN;
y2=zeros(M,1)+NaN;
for m=1:M
    str=out{m};
    sep=regexp(str,'\s');
    y1(m)=str2num(str(1:sep));
    y2(m)=str2num(str(sep(1):end));
end

for n=1:nargout
    eval(['varargout{n}=y' num2str(n) ';'])
end





