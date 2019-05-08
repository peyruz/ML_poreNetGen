% Generate a number of networks for the Machine Learning training dataset

%% Settings
% % Dataset
% % Number of training networks to generate
Ntr=1
% rMeanBounds=[]
% rStdBounds=[]
% thMeanBounds=[]
% thStdsBounds=[]

% Network
% poreNetInfo.fileName=

poreNetInfo.DomainW=1000;
poreNetInfo.DomainH=1000;

poreNetInfo.nPor=100;
poreNetInfo.porDist='normal';
poreNetInfo.thDist='normal';

meanRPor=50;
devRPor=5;

poreNetInfo.thDistParam.meanTh=10;
poreNetInfo.thDistParam.meanTh=1;

frame=ceil(meanRPor+3*devRPor);


%% Generation of training samples
% Preallocate
poreData=cell(Ntr,1);
thData=cell(Ntr,1);


for nn=1:Ntr
    warning off;
    
    % Random seed control for repeatability
    rng(1);
    
    % Create parallel pool if none exists.
    gcp;
    
    tic
    
%     poreNetInfo.fileName=strcat(poreNetInfo.baseFileName,{'_'},...
%         poreNetInfo.porShape,{'-'},...
%         poreNetInfo.thShape,{'.dxf'});
%     poreNetInfo.fileName=poreNetInfo.fileName{1};
%     
%     % Convert the input diameter-based values into radius-based
%     % Primary
%     switch poreNetInfo.porDist
%         case 'constant'
%             constRPor=poreNetInfo.porDistParam.constDPor/2;
%             frame=RPor;
%         case 'uniform'
%             porRLB=poreNetInfo.porDistParam.porUniDistLB/2;
%             porRUB=poreNetInfo.porDistParam.porUniDistUB/2;
%             frame=porRUB;
%         case {'normal','lognormal'}
%             meanRPor=poreNetInfo.porDistParam.meanDPor/2;
%             devRPor=poreNetInfo.porDistParam.devDPor/2;
%             frame=ceil(meanRPor+3*devRPor);
%         case 'custom'
%             porCumDistVar=poreNetInfo.porDistParam.porCumDistVar/2;
%             porCumDistProb=poreNetInfo.porDistParam.porCumDistProb;
%     end
%     
    bAlpha=poreNetInfo.DomainW/40; % alpha radius of the network boundary
    
    %% Generate Voronoi Tesselation for the primary porosity
    fprintf('Generating Voronoi tesselation..');
    
    % Generation of the random point cloud on which the network will be based
    poreNetInfo.nPor=round( (poreNetInfo.nPor + 33)/1.9 );
    prePor(:,1)=frame+(poreNetInfo.DomainW-2*frame)*rand(poreNetInfo.nPor,1);
    prePor(:,2)=frame+(poreNetInfo.DomainH-2*frame)*rand(poreNetInfo.nPor,1);
    
    % Generate the Delaunay and Voronoi tesselations
    TR=delaunayTriangulation(prePor);
    [centers,Regions]=voronoiDiagram(TR);
    
    % Remove out-of-domain regions
    centers(centers(:,1)>poreNetInfo.DomainW,:)=inf;
    centers(centers(:,2)>poreNetInfo.DomainH,:)=inf;
    centers(any([centers(:,1)<0, centers(:,2)<0],2),:)=inf;
    
    ii=1;
    needed=true;
    while needed
        if ismember(inf,centers(Regions{ii},:))
            Regions(ii)=[];
            ii=ii-1;
        end
        
        ii=ii+1;
        
        if ii>size(Regions,1)
            needed=false;
        end
    end
    
    % Exlude out-of-domain pores and update the 'Regions'.
    % Mask of in-domain pores
    maskRef=ismember(1:length(centers),cell2vec(Regions));
    
    % Refine region information
    cum=zeros(length(centers),1);
    cum(1)=maskRef(1);
    for ii=2:length(maskRef)
        cum(ii)=cum(ii-1)+maskRef(ii);
    end
    
    [newcode,oldcode]=unique(cum);
    
    newcode=newcode(2:end);
    oldcode=oldcode(2:end);
    
    nReg=length(Regions);
    
    for ii=1:nReg
        Regions{ii}=changem(Regions{ii},newcode,oldcode);
    end
    
    % Refine pore locations
    centers=centers(maskRef,:);
    
    % Construct edges from region information
    % Initialize the edges matrix
    % Count the anticipated number of edges
    numEdges=0;
    for ii=1:nReg
        numEdges=numEdges+numel(Regions{ii});
    end
    
    edges=zeros(numEdges,2);
    regID=zeros(numEdges,1);
    
    oo=1;
    
    for ii=1:nReg
        
        numVertInReg=numel(Regions{ii});
        
        for kk=1:numVertInReg
            if kk==numVertInReg
                edges(oo,:)=[Regions{ii}(kk) Regions{ii}(1)];
                regID(oo)=ii;
                oo=oo+1;
            else
                edges(oo,:)=[Regions{ii}(kk) Regions{ii}(kk+1)];
                regID(oo)=ii;
                oo=oo+1;
            end
        end
    end
    
    
    % Remove duplicate edges
    for ii=1:numEdges
        if ~isnan(edges(ii,1))
            mask1=all(edges==edges(ii,:),2);
            mask2=all(edges==fliplr(edges(ii,:)),2);
            mask12=any([mask1,mask2],2);
            mask12(ii)=false;
            edges(mask12,:)=NaN;
            edges(mask12,:)=NaN;
        else
            continue
        end
    end
    
    edges=edges(~isnan(edges(:,1)),:);
    
    % Coordinates of starting and ending points of each throat
    startsMidP=centers(edges(:,1),:);
    endsMidP=centers(edges(:,2),:);
    
    % Calculate total area of the domain (convex hull)
    outBound=convhull(centers(:,1),centers(:,2));
    
    totalArea=area(polyshape(centers(outBound,1),centers(outBound,2)));
    
    poreNetInfo.nPor=size(centers(:,1),1);   % Find number of pores
    poreNetInfo.nTh=size(startsMidP,1);   % Find number of throats
    
    fprintf('Done\n');
    
    %% Generate the sizes of pores and throats
    % Primary
    switch poreNetInfo.porDist
        case 'constant'
            radii=repmat(constRPor,poreNetInfo.nPor,1);
        case 'normal'
            radii=abs(normrnd(meanRPor,devRPor,poreNetInfo.nPor,1));
        case 'uniform'
            radii=abs(porRLB+(porRUB-porRLB)*rand(poreNetInfo.nPor,1));
        case 'lognormal'
            % Calculate the correspondent lognormal distribution parameters.
            lognMuPor=log(meanRPor^2/sqrt(meanRPor^2+devRPor));
            lognStdPor=sqrt(log(devRPor/meanRPor^2+1));
            radii=abs(lognrnd(lognMuPor,lognStdPor,poreNetInfo.nPor,1));
        case 'custom'
            radii=abs(genCustRand(porCumDistProb,porCumDistVar,poreNetInfo.nPor));
    end
    
    switch poreNetInfo.thDist
        case 'constant'
            widths=repmat(poreNetInfo.thDistParam.constThWidth,poreNetInfo.nTh,1);
        case 'normal'
            widths=abs(normrnd(poreNetInfo.thDistParam.meanTh,poreNetInfo.thDistParam.devTh,poreNetInfo.nTh,1));
        case 'uniform'
            widths=abs(poreNetInfo.thDistParam.thUniDistLB+(poreNetInfo.thDistParam.thUniDistUB-poreNetInfo.thDistParam.thUniDistLB)*rand(nTh,1));
        case 'lognormal'
            % Calculate the correspondent lognormal distribution parameters.
            lognMuTh=log(poreNetInfo.thDistParam.meanTh^2/sqrt(poreNetInfo.thDistParam.meanTh^2+poreNetInfo.thDistParam.devTh));
            lognStdTh=sqrt(log(poreNetInfo.thDistParam.devTh/poreNetInfo.thDistParam.meanTh^2+1));
            widths=abs(lognrnd(lognMuTh,lognStdTh,poreNetInfo.nTh,1));
        case 'custom'
            widths=abs(genCustRand(poreNetInfo.thDistParam.thCumDistProb,poreNetInfo.thDistParam.thCumDistVar,poreNetInfo.nTh));
    end
    
    %% Merge the overlapping primary pores if requested by user
    if poreNetInfo.MergeOverlappingPores
        fprintf('Merging Overlapping Pores..')
        [centers,radii,startsMidP,endsMidP,widths,Regions]=PoreMerger2(centers,radii,startsMidP,endsMidP,widths,Regions,edges);
        fprintf('Done \n')
        % Recalculate the number of pores and throats
        poreNetInfo.nPor=size(centers,1);
        poreNetInfo.nTh=size(startsMidP,1);
    end
    
    % Delete the pores removed during merging (denoted by NaN)
    NaNMask=isnan(radii);
    radii=radii(~NaNMask);
    centers=centers(~NaNMask,:);
    poreNetInfo.nPor=length(radii);
    poreNetInfo.nTh=length(widths);

    % Generate the DXF file
    %% Generate pores
fprintf('Generating pores..')
% Primary
switch poreNetInfo.porShape
    
    case 'irregular'
        % Generate the polygons
        x = irrPolGen_Par1_2(radii,poreNetInfo.Pore_Spiky,poreNetInfo.Pore_ScaleOfDetail);
        % Plot the pores
        for ii=1:poreNetInfo.nPor
            % Translate  the barycenter of the polygon to the given pore location
            x{ii} = x{ii} + centers(ii,:);
        end
        
    case 'circle'
        % Generate the circles
        x = circleGen(radii);
        
        % Plot the pores
        for ii=1:poreNetInfo.nPor
            % Translate  the center of the circle to the given pore location
            x{ii} = x{ii} + centers(ii,:);
        end
        
    case 'triangle'
        % Generate the squares
        x = triGen(radii);
        
        % Plot the pores
        for ii=1:poreNetInfo.nPor
            % Translate  the center of the circle to the given pore location
            x{ii} = x{ii} + centers(ii,:);
        end
        
    case 'square'
        % Generate the squares
        x = sqGen(radii);
        
        % Plot the pores
        for ii=1:poreNetInfo.nPor
            % Translate  the center of the circle to the given pore location
            x{ii} = x{ii} + centers(ii,:);
        end
        
end
    fprintf('Done \n')

%% Generate throats
fprintf('Generating throats..')
% Primary
% Calculate throat direction vectors
throatVecs=[endsMidP(:,1)-startsMidP(:,1), endsMidP(:,2)-startsMidP(:,2)];
throatLengths=(throatVecs(:,1).^2+throatVecs(:,2).^2).^0.5;
throatVecs=throatVecs./repmat(throatLengths,1,2);

switch poreNetInfo.thShape
    
    case 'rough'
        % Generate rough rectangles
        xt = RoughRecGen3(throatLengths, widths,throatVecs,...
            poreNetInfo.Throat_Spiky,...
            poreNetInfo.Throat_ScaleOfDetail,...
            poreNetInfo.Throat_WiggleAmount);
        
        % Translate  left-middle point of the rectangle to the desired location
        for ii=1:poreNetInfo.nTh
            xt{ii} = xt{ii}+repmat( throatVecs(ii,:)*throatLengths(ii)/2+startsMidP(ii,:),size(xt{ii},1),1 );
        end
        
    case 'smooth'
        % Generate rough rectangles
        xt = recGen(throatLengths, widths,throatVecs);
        
        % Translate  left-middle point of the rectangle to the desired location
        for ii=1:poreNetInfo.nTh
            xt{ii} = xt{ii}+repmat( throatVecs(ii,:)*throatLengths(ii)/2+startsMidP(ii,:),size(xt{ii},1),1 );
        end
        
end

% Grain
if poreNetInfo.GrainPorosity
    % Calculate grain throat direction vectors
    grThroatVecs=[grEndsMidP(:,1)-grStartsMidP(:,1), grEndsMidP(:,2)-grStartsMidP(:,2)];
    grThroatLengths=(grThroatVecs(:,1).^2+grThroatVecs(:,2).^2).^0.5;
    grThroatVecs=grThroatVecs./repmat(grThroatLengths,1,2);
    
    switch poreNetInfo.thShape
        
        case 'rough'
            % Generate rough rectangles
            xgrt = RoughRecGen3(grThroatLengths, grWidths,grThroatVecs,...
                poreNetInfo.grThroat_Spiky,...
                poreNetInfo.grThroat_ScaleOfDetail,...
                poreNetInfo.grThroat_WiggleAmount);
            
            % Translate  left-middle point of the rectangle to the desired location
            for ii=1:poreNetInfo.gr_nTh
                xgrt{ii} = xgrt{ii}+repmat( grThroatVecs(ii,:)*grThroatLengths(ii)/2+grStartsMidP(ii,:),size(xgrt{ii},1),1 );
            end
            
        case 'smooth'
            % Generate rough rectangles
            xgrt = recGen(grThroatLengths, grWidths,grThroatVecs);
            
            % Translate  left-middle point of the rectangle to the desired location
            for ii=1:poreNetInfo.gr_nTh
                xgrt{ii} = xgrt{ii}+repmat( grThroatVecs(ii,:)*grThroatLengths(ii)/2+grStartsMidP(ii,:),size(xgrt{ii},1),1 );
            end
    end
    xt=[xt,xgrt];
end

fprintf('Done \n')

x=[x,xt];


%% Union the pores and throats
fprintf('Performing polygon boolean operations..')
[shapeCell , porArea] = unionMultiShapes(x, 512, 256);
fprintf('Done \n')

poreNetInfo.porosity = porArea / totalArea;

% ------------ Correct the next line, adjust for new parameters
% ---------------------------%%%
% poreNetInfo=orderfields(poreNetInfo,{'nPor','meanPor','devPor','porShape','MergeOverlappingPores','nTh','meanTh','devTh','thShape','fileName','porosity'});

fprintf('Generating the DXF file..')
genDXF(shapeCell, poreNetInfo.DomainW, poreNetInfo, poreNetInfo.fileName);
fprintf('Done \n \n')
fprintf('Total generation time: %1.2f seconds \n', toc)

end