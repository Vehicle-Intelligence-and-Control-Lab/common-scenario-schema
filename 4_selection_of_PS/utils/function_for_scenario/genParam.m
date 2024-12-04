function paramTable = genParam(parameters_input,samples_input,toggle_randomSampling)
%GENPARAM Create a parameter space consisting of concrete scenarios.
%
%   paramTable = genParam(samplesOf_paramSpace_table) returns a table parameter space
%   by even space parameter sampling and calling combinations.
%
%   입력 인수:
%   -------
%   parameters                      - 시나리오에서 정의된 N개의 파라미터 이름 (cell, 1 x N)
%   samples                         - 시나리오에서 정의된 N개의 파라미터에 대한 값(?) (cell, 1 x N)
%   toggle_randomSampling           - 랜덤 샘플링 여부 (double, 1 x N)
%
%   출력 인수:
%   --------
%   paramTable                      - 시나리오의 파라미터 스페이스 (table)
%
%   There is an example for genParam in OneDrive. 
%    Please go to METISlib/examples/CreateANewParameterSpaceForCutinScenarioExample.mlx

sample = {};
for idx_samples_input = 1 : length(parameters_input)
    Cur_toggle_randomSampling = toggle_randomSampling(idx_samples_input);
    Cur_parameters_input = parameters_input{idx_samples_input};
    Cur_sample_input_tmp = double(samples_input{idx_samples_input});

    if Cur_toggle_randomSampling
        Cur_sample_input = Cur_sample_input_tmp(1) + rand(1,Cur_sample_input_tmp(3))*(Cur_sample_input_tmp(2)-Cur_sample_input_tmp(1));

        disp(['Sampling mode of "' Cur_parameters_input '") ' replace(num2str(Cur_toggle_randomSampling),{'0','1'},{'deterministic','randome'})])
        disp([' Minimum of range) ' num2str(Cur_sample_input_tmp(1))])
        disp([' maximum of range) ' num2str(Cur_sample_input_tmp(2))])
        disp([' Number of samples) ' num2str(Cur_sample_input_tmp(3))])
        disp([' Samples) ' num2str(Cur_sample_input)])
        disp(' ')

    else
        Cur_sample_input = Cur_sample_input_tmp;        

        disp(['Sampling mode of "' Cur_parameters_input '") ' replace(num2str(Cur_toggle_randomSampling),{'0','1'},{'deterministic','randome'})])
        disp([' Minimum of range) ' num2str(max(Cur_sample_input_tmp))])
        disp([' maximum of range) ' num2str(min(Cur_sample_input_tmp))])
        disp([' Number of samples) ' num2str(length(Cur_sample_input_tmp))])
        disp([' Samples) ' num2str(Cur_sample_input)])
        disp(' ')

    end

    sample = [sample ; {Cur_sample_input}];

end

cmdForCombinations_tmp = cellfun(@(v) ['[' num2str(v) ']'],sample,'UniformOutput',false);
cmdForCombinations                  = strjoin(cmdForCombinations_tmp,',');

paramArray                          = eval(['combinations(' cmdForCombinations ')']);
paramArray.Properties.VariableNames = transpose(parameters_input);

variations                          = array2table(transpose(0:height(paramArray)-1),'VariableNames',{'Variation'});
paramTable                          = [variations paramArray];

end

%% Sub function
function T = combinations(varargin)
%COMBINATIONS Generate all element combinations of arrays
%
%   T = COMBINATIONS(A1, A2, ..., An) returns all element combinations.
%   Each row in output table T is a combination with the first element
%   coming from A1, the second element coming from A2, and so on. The
%   number of rows in T is the product of the number of elements in each
%   input, and the number of variables in T is the number of inputs.
% 
%   The inputs can be vectors, matrices, or multidimensional arrays. If an
%   input Ak is not a vector, then COMBINATIONS treats it as a single
%   column vector, Ak(:).
%
%   See also REPELEM, REPMAT, PERMS, NCHOOSEK, NDGRID, MESHGRID in MATLAB
%           and "cartesian product" in Wikipedia

%   Copyright 2022-2023 The MathWorks, Inc.

narginchk(1,Inf);

numVars = nargin;
varNumel = zeros(1,numVars);
input = varargin;
for k = 1:numVars
    varNumel(k) = numel(input{k});
end

m = prod(varNumel);

% Gracefully error like in perms()
[~,maxsize] = computer;
if m*numVars > maxsize
    error(message('MATLAB:pmaxsize'))
end

vars = cell(1,numVars);
varNames = cell(1,numVars);
noName = false(1,numVars);
for k = 1:numVars
    var = input{k}(:);
    r = repelem(var,prod(varNumel(k+1:end)),1);
    vars{:,k} = repmat(r,prod(varNumel(1:k-1)),1);
    varNames{k} = inputname(k);
    noName(k) = isempty(varNames{k});
end

% Construct output table containing the combinations 
% Use default table variable names for inputs with no name
numNoName = sum(noName);
if numNoName > 0
    vdim = matlab.internal.tabular.private.varNamesDim;
    varNames(noName) = vdim.dfltLabels(find(noName));
end

% Disambiguate reserved names for table variables
if numNoName < numVars
    mdim = matlab.internal.tabular.private.metaDim;
    rlabels = mdim.labels;
    rnames = matlab.internal.tabular.private.varNamesDim.reservedNames;
    r = [rlabels rnames];
    varNames = matlab.lang.makeUniqueStrings(varNames,r,namelengthmax);
end
T = table.init(vars,m,{},numVars,varNames);
end