% Union of the polyline-defined shapes contained in the cell array x
% 
% by Peyruz Gasimov

function [shapeCell, porArea] = unionMultiShapes(x, srx, sry)

xmax=max(cell2mat(cellfun(@max,x,'un',0)'));

xmin=min(cell2mat(cellfun(@min,x,'un',0)'));

% Pad the boundaries
span=xmax-xmin;
xmin=xmin-0.1*span;
xmax=xmax+0.1*span;

IWsizeX=round((xmax(1)-xmin(1))/srx);
IWsizeY=round((xmax(2)-xmin(2))/sry);

% Find the centroids of the elements
xmean = cell2mat(cellfun(@mean,x,'un',0)');

% Find to which subregion each element belongs
IWaddressX=ceil(xmean(:,1)/IWsizeX);
IWaddressY=ceil(xmean(:,2)/IWsizeY);

% Find the address in the form of a linear index
IWadressLin=(IWaddressX-1)*sry+IWaddressY;

% Number of subregions
numIW=srx*sry;

%% Union the elements within the initial subregions
shapeCell=cell(1,numIW);

for ii=1:numIW
    
    mask=IWadressLin==ii;
    if any(mask) == 0
%         if ii==numIW
            shapeCell{ii}=[];
%         end
        continue
    end
    
    % Generate polyvector
    xmasked=x(mask);
    polynum=sum(mask);
    
    for kk=1:polynum
        polyvec(kk)=polyshape(xmasked{kk});
    end
    
    % Union within the partitions
    shapeCell{ii}=union(polyvec);
    
end

%% Recursively union the domain partitions until a single one is left containing all the shapes united

offset=0:2:(numIW-2);
NewShapeCell=cell(1,numel(shapeCell)/2);

for jj=1:log2(numIW)
    
    for ii=1:numel(shapeCell)/2
        
        empty1=isempty(shapeCell{1+offset(ii)});
        empty2=isempty(shapeCell{2+offset(ii)});
        
        if empty1 && empty2
            NewShapeCell{ii}=[];
            continue
        elseif empty1 && ~empty2
            NewShapeCell{ii}=shapeCell{2+offset(ii)};
            continue
        elseif ~empty1 && empty2
            NewShapeCell{ii}=shapeCell{1+offset(ii)};
            continue
        else
            NewShapeCell{ii}=union(shapeCell{1+offset(ii)},shapeCell{2+offset(ii)});
        end
        
    end
    
    if jj==log2(numIW)
        shapeCell=NewShapeCell;
    else
        shapeCell=NewShapeCell;
        NewShapeCell=cell(1,numel(shapeCell)/2);
    end
    
end

%%

% Compute the pore area of the network
porArea=area(shapeCell{1});

% Generate the output
shapeCell=shapeCell{1}.Vertices;