%% Generating IDU partnership and transmissions
%% Input
initialNbIDU = 1000;
nbIDU = initialNbIDU;
nbIDUF = 50000;
nbIDUM = 50000;
nbIDUMSM = 20000;
sexDist = [0.3, 0.5, 0.2];
sexCumDist = [0.3, 0.8, 1.0];
ptnrMixDist = [0.3, 0.6, 0.1; 0.6, 0.3, 0.1; 0.2, 0.1, 0.7];
ptnrMixCumDist = [0.3, 0.9, 1.0; 0.6, 0.9, 1.0; 0.2, 0.3, 1.0];

sex = zeros(nbIDU, 1);
for iIDU = 1:nbIDU
    rnd = rand();
    if rnd <= sexCumDist(1)
        sex(iIDU) = 1;
    elseif rnd <= sexCumDist(2)
        sex(iIDU) = 2;
    else
        sex(iIDU) = 3;
    end
end

% minPercIDUShare = 0.15;
% maxPercIDUShare = 0.45;
minPtnr = 1;
maxPtnr = 10;
maxSimPeriod = 120;
ptnrUpdatePeriod = 6;
minNeedle = 20/12;
maxNeedle = 200/12;
minPercNeedleShare = 0.05;
maxPercNeedleShare = 0.25;
transRateNeedle = 63/10000;
nbTrans = 0;
for iPeriod = 1:maxSimPeriod
    prev = [sum(sex == 1)/nbIDUF, sum(sex == 2)/nbIDUM, sum(sex == 3)/nbIDUMSM];
    if mod(iPeriod, ptnrUpdatePeriod) == 1
        nbPtnr = round(rand(nbIDU, 1) * (maxPtnr - minPtnr)) + minPtnr;
        percActs = rand(nbIDU, 1) * (maxPercNeedleShare - minPercNeedleShare) + minPercNeedleShare;
        nbActs = round(rand(nbIDU, 1) * (maxNeedle - minNeedle) + minNeedle);
        nbActsPerPtnr = round(nbActs ./ nbPtnr);
        ptnrSex = zeros(nbIDU, maxPtnr);
        ptnrHIVProb = ptnrSex;
        transProb = ptnrSex;
        for iIDU = 1:nbIDU
            for iPtnr = 1:nbPtnr(iIDU)
                rnd = rand();
                if rnd <= ptnrMixCumDist(sex(iIDU), 1)
                    ptnrSex(iIDU, iPtnr) = 1;
                    ptnrHIVProb(iIDU, iPtnr) = prev(1);
                elseif rnd <= ptnrMixCumDist(sex(iIDU), 2)
                    ptnrSex(iIDU, iPtnr) = 2;
                    ptnrHIVProb(iIDU, iPtnr) = prev(2);
                else
                    ptnrSex(iIDU, iPtnr) = 3;
                    ptnrHIVProb(iIDU, iPtnr) = prev(3);
                end
                transProb(iIDU, iPtnr) = 1 - (1 - transRateNeedle * percActs(iIDU)) ^ nbActsPerPtnr(iIDU);
            end
        end
        ptnrHIV = rand(nbIDU, maxPtnr) <= ptnrHIVProb;
    end
  
    for iIDU = 1:nbIDU
        for iPtnr = 1:nbPtnr(iIDU)
            if ptnrHIV(iIDU, iPtnr) == 0 && rand() <= transProb(iIDU, iPtnr)
                nbTrans = nbTrans + 1;
                nbIDU = nbIDU + 1;
                nbPtnr = [nbPtnr; round(rand() * (maxPtnr - minPtnr)) + minPtnr];
                percActs = [percActs; rand() * (maxPercNeedleShare - minPercNeedleShare) + minPercNeedleShare];
                nbActs = [nbActs; round(rand() * (maxNeedle - minNeedle) + minNeedle)];
                nbActsPerPtnr = [nbActsPerPtnr; round(nbActs ./ nbPtnr)];
                ptnrSex = [ptnrSex; zeros(1, maxPtnr)];
                ptnrHIVProb = [ptnrHIVProb; zeros(1, maxPtnr)];
                transProb = [transProb; zeros(1, maxPtnr)];
                rnd = rand();
                if rnd <= sexCumDist(1)
                    sex = [sex; 1];
                elseif rnd <= sexCumDist(2)
                    sex = [sex; 2];
                else
                    sex = [sex; 3];
                end
                ptnrSex = [ptnrSex; zeros(1, maxPtnr)];
                ptnrHIVProb = [ptnrHIVProb; zeros(1, maxPtnr)];
                ptnrHIV = [ptnrHIV; zeros(1, maxPtnr)];
                if rnd <= ptnrMixCumDist(sex(end), 1)
                    ptnrSex(iIDU, iPtnr) = 1;
                    ptnrHIVProb(iIDU, iPtnr) = prev(1);
                elseif rnd <= ptnrMixCumDist(sex(end), 2)
                    ptnrSex(iIDU, iPtnr) = 2;
                    ptnrHIVProb(iIDU, iPtnr) = prev(2);
                else
                    ptnrSex(iIDU, iPtnr) = 3;
                    ptnrHIVProb(iIDU, iPtnr) = prev(3);
                end
                ptnrHIV(end, :) = rand(1, maxPtnr) <= ptnrHIVProb(end, :);
            end
        end
    end
end


