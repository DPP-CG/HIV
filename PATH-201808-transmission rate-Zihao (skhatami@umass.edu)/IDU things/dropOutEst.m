nb = 10000;
nbActsUA = zeros(nb, 1);
nbActsAW = zeros(nb, 1);
nbActsART = zeros(nb, 1);

for i = 1:nb
    rdnb = rand();
    if rdnb <= 0.657
        nbActsUA(i) = 360 + (-log(rand())/0.01);
    elseif rdnb <= 0.778
        nbActsUA(i) = 270 + round(rand() * (450 - 270), 0);
    elseif rdnb <= 0.908
        nbActsUA(i) = 50 + round(rand() * (360 - 50), 0);
    else
        nbActsUA(i) = round(rand() * 50, 0);
    end
    
    rdnb = rand();
    if rdnb <= 0.661
        nbActsAW(i) = 360 + (-log(rand())/0.01);
    elseif rdnb <= 0.757
        nbActsAW(i) = 270 + round(rand() * (450 - 270), 0);
    elseif rdnb <= 0.892
        nbActsAW(i) = 50 + round(rand() * (360 - 50), 0);
    else
        nbActsAW(i) = round(rand() * 50, 0);
    end
    
    rdnb = rand();
    if rdnb <= 0.536
        nbActsART(i) = 360 + (-log(rand())/0.01);
    elseif rdnb <= 0.653
        nbActsART(i) = 270 + round(rand() * (450 - 270), 0);
    elseif rdnb <= 0.842
        nbActsART(i) = 50 + round(rand() * (360 - 50), 0);
    else
        nbActsART(i) = round(rand() * 50, 0);
    end
        
end

(sum(nbActsUA) - sum(nbActsAW))/sum(nbActsUA)
(sum(nbActsUA) - sum(nbActsART))/sum(nbActsART)
