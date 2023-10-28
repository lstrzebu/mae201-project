% Project 1 Optimization
% MAE 201
% Nathan McClamroch, Liam Trzebunia-Niebies
% October 10, 2023
clear;clc;close all;

%  READ: this model outputs incorrect values because it uses the original
%  input power value instead of generating a new input power value using
%  the necessary number of pumps.

% % set a social score value
% socialValueInDays = 10; % Arbitrary

% neglect filter value

%% Read Input Data
eleCostData = readcell("MAE201ProjectCost.xlsx");
blocksOfHours = convertCharsToStrings(eleCostData(2:end,1)); % blockOfHours data to print to help a human reader figure out what the Matlab program wants to do
% blockOfHours = [eleCostData{2:end,1}]';
electriCost = [eleCostData{2:end,2}]'; % trim unneeded info
socialScore = [eleCostData{2:end,3}]';

pipeData = readcell("MAE201ProjectPipe.xlsx");
pipingNames = convertCharsToStrings(pipeData(2:end,1));
costPerFoot = [pipeData{2:end,2}]';
yearlyMaintenanCost_pipe = [pipeData{2:end,3}]';
bpm = [pipeData{2:end,4}]'; % barrels per minute

pumpData = readcell('MAE201ProjectPump.xlsx');
pumpNames = convertCharsToStrings(pumpData(2:end,1));
pumpBaseCost = [pumpData{2:end,2}]';
yearlyMaintenanCost_pump = [pumpData{2:end,3}]';
individualPumpOutput = [pumpData{2:end,6}]';
pumpEfficiencies = [pumpData{2:end,5}]';

%% Write Output Data
fid = fopen('MAE_208_Project1_Results_V15.csv', 'w'); % open output file
fprintf(fid, 'payback time, social score, pump, pipe, requiredInput, desiredOutput, number of pumps, initial cost, annual cost, annual revenue, filter, time blocks used\n'); % print header to output file

%% Loops
% completedIterations = 0; % preallocate simulation counter
load("MAE 201 Project 1 Simulation Counter.mat", 'completedIterations'); % load current number of simulations run

% % dry run for pump 10 (Huge Pump) and Pipe 7 (Tremendous Pipe)
% pumpIndx = 10;
% pipeIndx = 7;

numElectriCombinations = 10;
numPossiblePumps = 17;
numPossiblePipes = 15;
numPossibleFilters = 4;
% numTimeBlockSims = 2;

numSimulationsExpected = completedIterations + numPossiblePipes*numPossiblePumps*numElectriCombinations*numPossibleFilters;
fprintf('%d iterations expected\n', numSimulationsExpected)

pumpIndx = 13;
pipeIndx = 6;
filterType = 1;

% for pumpIndx = 1:numPossiblePumps
%     for pipeIndx = 1:numPossiblePipes
%         for k = 1:numElectriCombinations
%             for filterType = 0:3 % instead of considering all possible filters, use the one with highest social score benefit
                % for typeOfTimeBlock = 1:numTimeBlockSims

                [filterCost, filterBenefit] = thermoFilter(filterType); % get initial cost and social score benefit. For other design parameters, this is done by reading an Excel table instead of calling a custom (hardcoded) function.

                % switch typeOfTimeBlock % decide whether to use a random combination/permutation or all time blocks
                %     case 1
                % timeBlocksUsed = unique(randi([1 8], [1 randi([4 8])])); % unique, random combinations (and permutations?) of numbers from 1 to 8
                % timeBlocksUsed = unique(randi([1 8], [2 10])); % more situationally relevant random time block generation
                timeBlocksUsed = 1:8; % blocks of hours for which we purchase electricity, daily
                %     case 2
                %         timeBlocksUsed = 1:8; % use all possible time blocks
                % end

                netSocialScore = sum(socialScore(timeBlocksUsed)) + filterBenefit; % social score decreased by electricity costs and raised by the use of a filter

                %% Calculations

                % Phase 1 data
                h = 200; % change in height in ft
                deltaz = h/3.281; % change in height converted to m
                rho_oil = 800; % kg/m^3

                debt = 0; % initial investments
                g = 9.8067; % m/s^2
                % bpm = 30; % barrels per minute
                v = 0.15899; % m^3
                vdot = bpm(pipeIndx)*v/60; % (barrels/min)(m^3/barrel)(mins/s)
                %vdot = 0.079495; % (m^3/s) placeholder value for vdot which will be determined by a function later
                mdot = rho_oil*vdot;
                P_atm = 101.325e3; % Pa
                deltap = rho_oil*g*deltaz;
                % runTime = 100; % total runtime in hrs
                barrelFillTime = v/vdot; % time to fill 1 barrel of oil
                sellPrice = 19; % $/barrel

                % syms inPower
                deltaedot_mechfluid = deltap/rho_oil + g*deltaz; % neglect kinetic energy
                deltaEdot_mechfluid = mdot*deltaedot_mechfluid; % convert from lowercase (specific) to uppercase equation
                desiredOutput = deltaEdot_mechfluid;
                eta_pump = pumpEfficiencies(pumpIndx); % 24.0% efficiency for stupendous pump, arbitrary placeholder for a value that will come out of pump function
                requiredInput = desiredOutput/eta_pump;
                inPower = requiredInput;
                % energy_in = inPower*runTime;

                numPumps = ceil((desiredOutput/1000)/individualPumpOutput(pumpIndx)); % divide by 1000 to convert from W to kW

                blocksOfHoursCost = 0; % preallocate

                dailyRunRate = 3*numel(timeBlocksUsed); % number of hrs which the arbitrary placeholder for a runRate that will come out of electricity function later
                annualRevenue = dailyRunRate*sellPrice*3600*(1/barrelFillTime)*365;
                % dailyProfit = dailyRunRate*sellPrice*runTime*3600/barrelFillTime; % ($/barrel)(barrel/s)

                for timeBlock = 1:length(timeBlocksUsed)
                    blocksOfHoursCost = blocksOfHoursCost + electriCost(timeBlocksUsed(timeBlock))*3; % first part of the sum that will become annualCost ($/(kWh*day))
                end

                syms t % setup t in yrs to solve for
                annualCost = blocksOfHoursCost*365*(requiredInput/1000) + yearlyMaintenanCost_pump(pumpIndx)*numPumps + yearlyMaintenanCost_pipe(pipeIndx); % cost paid for electricity and maintenance ($/yr) (divide W by 1000 to get kW)
                initialCost = pumpBaseCost(pumpIndx)*numPumps + h*costPerFoot(pipeIndx) + filterCost; % cost paid up front for pumps and pipes ($/yr)

                % if annualCost <= annualRevenue % if solution might be valid

                y1 = annualCost*t + initialCost; % line equation for cost
                y2 = annualRevenue*t; % line equation for revenue
                setEqual = y1 == y2; % equate cost and revenue equations to find intercept
                t_intercept = solve(setEqual, t); % solve for intercept (this is payback time)


                fprintf(fid, '%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %s\n', t_intercept, netSocialScore, pumpIndx, pipeIndx, requiredInput, desiredOutput, numPumps, initialCost, annualCost, annualRevenue, filterType, num2str(timeBlocksUsed));
                % for timeBlockToPrint = 1:numel(timeBlocksUsed)
                %     fprintf('%d ', blocksUsed(timeBlockToPrint));
                % end
                % fprintf(fid, '\n'); % new line
                % end

                completedIterations = completedIterations + 1;
                if rem(completedIterations, 100) == 0 % print occasionally to not flood the command window
                    fprintf('%d completed iterations\n', completedIterations);
                end

                %% End of Loops
                % end
%             end
%         end
%     end
% end

fclose(fid); % close output file

save('MAE 201 Project 1 Simulation Counter', 'completedIterations'); % save number of simulations to a counter

%% Unneeded

% % cost_in = electriCost();
% ratio = desiredOutput/bpm;
% $0.14/kWh for 3 hrs and then $0.15/kWh for the next 3 hrs
% pump info
% piping materials info
% V_dot_engmin = ;






