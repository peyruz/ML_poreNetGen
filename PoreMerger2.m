% Merge overlapping pores
%
% modified Jun 11, 2018
% the code is now more robust for severe multiple overlap cases
% 
% version 2, July 25, 2018
% added feature of additionally adjusting the network cycles. This feature
% is critical for merging to work in dual porosity settings.
% + corrected code line for temporary removal of corrected edges from analysis
% 
% by Peyruz Gasimov, July 2018

function [centers,radii,startsMidP,endsMidP,widths,varargout]=PoreMerger2(centers,radii,startsMidP,endsMidP,widths,varargin)


% Input analysis

% Grain porosity flag. False if no region data are input/output.
grFlag=false;

if nargin>=7
    if nargout>=6
        Regions=varargin{1};
        edgeIx=varargin{2};
    else
        error('Regions not requested at the output, but are input.');
    end
elseif  nargin==5
    if nargout>=6
        error('Missing Regions (6th input), edge-region affiliation (7th input) info and edge info (8th input) in the input.')
    else
        % In this case the function is dealing with grain porosity.
        grFlag=true;
    end
else 
    error('Invalid number of inputs.');
end

if grFlag
    % Calculate edge info in the form of vertex IDs
    edgeIx=zeros(size(startsMidP));
    
    nPor=length(centers);
    
    for ii=1:nPor
        edgeIx(all(startsMidP==centers(ii,:),2),1)=ii;
        edgeIx(all(endsMidP==centers(ii,:),2),2)=ii;
    end
    
    % For grain porosity
    % Find link throats (thoats which connect grain and main porous spaces)
    linkThMask=edgeIx(:,1)==0 | edgeIx(:,2)==0;
    % Temporarily remove the link throats
    edgeIx(linkThMask,:)=[];
end

% Perform initial overlapping test
overlappingPoresMask = radii(edgeIx(:,1))+radii(edgeIx(:,2)) > normMat2d((centers(edgeIx(:,1),:)-centers(edgeIx(:,2),:))')';
unmergedRemain = any(overlappingPoresMask);

edgeNum_0=size(edgeIx,1);
if ~grFlag
    nReg=length(Regions);
end

while unmergedRemain
    
    for ii=1:edgeNum_0
        
        if overlappingPoresMask(ii)
            % Substitute the two overlapping pores with a single,
            % positioned midway between the pores
            centers(edgeIx(ii,1),:)= mean( [centers(edgeIx(ii,1),:); centers(edgeIx(ii,2),:) ], 1 );
            centers(edgeIx(ii,2),:) = [NaN, NaN];
            
            % Radius of the new pore equals mean of the two parent pores
            radii(edgeIx(ii,1))=mean([radii(edgeIx(ii,1)), radii(edgeIx(ii,2))]);
            radii(edgeIx(ii,2))=NaN;
            
            % Adjust the region info
            if ~grFlag
                Regions=cellfun(@(x) changem(x,edgeIx(ii,1),edgeIx(ii,2)), Regions,'UniformOutput',0);
            end
            
            % Remove the edges associated with the removed and adjusted pores
            % from the overlapping mask until the end of the iteration
            % (important!). More iterations, but simpler and more robust
            % code.
            overlappingPoresMask(any(edgeIx == edgeIx(ii,1),2))=false;
            overlappingPoresMask(any(edgeIx == edgeIx(ii,2),2))=false;
            
            % Remove the second pore from edge info
            edgeIx(edgeIx == edgeIx(ii,2)) = edgeIx(ii,1);

        end
        
    end
    
    throatLengths=normMat2d((centers(edgeIx(:,1),:)-centers(edgeIx(:,2),:))')';
    
    % Adjust so that the pores are not labeled as overlapping in the next
    % line
    throatLengths(throatLengths==0)=inf;
    
    % Check overlapping
    overlappingPoresMask = radii(edgeIx(:,1))+radii(edgeIx(:,2)) > throatLengths;
    unmergedRemain = any(overlappingPoresMask);
end

% Clear out the removed edges
nullEdgesMask=edgeIx(:,1)==edgeIx(:,2);
edgeIx(nullEdgesMask,:)=[];

if grFlag
    % Reestablish the throats' starting and ending points and add the removed
    % link throats
    startsMidP = [centers(edgeIx(:,1),:);startsMidP(linkThMask,:)];
    endsMidP = [centers(edgeIx(:,2),:);endsMidP(linkThMask,:)];
    tempWidth=widths(~linkThMask);
    widths=[tempWidth(~nullEdgesMask); widths(linkThMask)];
else
     startsMidP = centers(edgeIx(:,1),:);
     endsMidP = centers(edgeIx(:,2),:);
     widths=widths(~nullEdgesMask);
end

%% Clear out the elements associated with the removed throats
% widths(nullEdgesMask)=[];
% startsMidP(nullEdgesMask,:)=[];
% endsMidP=endsMidP(~nullEdgesMask,:);
% radii=radii(~isnan(radii(:,1)),:);

% Refine pore locations
% maskRef=~isnan(centers(:,1));
% centers=centers(maskRef,:);

% % Adjust the Regions
% if ~grFlag
%     % Refine region information
%     cum=zeros(length(centers),1);
%     cum(1)=maskRef(1);
%     for ii=2:length(maskRef)
%         cum(ii)=cum(ii-1)+maskRef(ii);
%     end
%     
%     [newcode,oldcode]=unique(cum);
%     
%     newcode=newcode(2:end);
%     oldcode=oldcode(2:end);
%     
%     for ii=1:nReg
%         Regions{ii}=changem(Regions{ii},newcode,oldcode);
%     end
% end
% 
% 


% Assign varargout
if nargout>=6 && ~grFlag
    varargout{1}=Regions;
end



