function [monCost, socialScoreBen] = thermoFilter(filterType)
% retrieves filter data for a given type of filter used for MAE 201
% Project 1
%   filterType: integer from 0 to 3 representing no filter, lite filter, plain filter or power filter
%   monCost: monetary cost incurred by buying the filter
%   socialScoreBen: benefit to social score from buying the filter

switch filterType
    case 0 % no filter
        monCost = 0;
        socialScoreBen = 0;
    case 1 % lite filter
        monCost = 5e6;
        socialScoreBen = 3;
    case 2 % plain filter
        monCost = 10e6;
        socialScoreBen = 6;
    case 3 % power filter
        monCost = 15e6;
        socialScoreBen = 9;
end