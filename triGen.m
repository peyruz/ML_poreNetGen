% Generate vertices of triangles with sizes corresponding to the eqRadii
% 
% by Peyruz Gasimov. April, 2018
function x = triGen(eqRadii)

nTri=max(size(eqRadii));

% Min and max angles allowed
minAngle=deg2rad(30);
maxAngle=deg2rad(90);

% Generate initial base length
L=rand(1,nTri);
% Generate the angles
angles1=normrnd((maxAngle-minAngle)/2, deg2rad(5),1,nTri);
angles2=normrnd((maxAngle-minAngle)/2, deg2rad(5),1,nTri);

lastAngleTestFails=1;

% Check the last angle (whether it resides between minAngle and maxAngle)
while lastAngleTestFails
    
    lastAngleTest1 = pi-(angles1+angles2)<minAngle;
    lastAngleTest2 = pi-(angles1+angles2)>maxAngle;
    lastAngleTest = any([lastAngleTest1; lastAngleTest2],1);
    
    numberFailed=sum(lastAngleTest);
    
    if numberFailed==0
        lastAngleTestFails=0;
        break;
    end
    
    angles1(lastAngleTest)=normrnd((maxAngle-minAngle)/2, deg2rad(10),1,numberFailed);
    angles2(lastAngleTest)=normrnd((maxAngle-minAngle)/2, deg2rad(10),1,numberFailed);
    
end

c1=cos(angles1);
c2=cos(angles2);
s1=sin(angles1);
s2=sin(angles2);

% Preallocate
x=cell(1,nTri);

% Generate the triangle vertices
for jj=1:nTri
    
    % Solve the system of equations describing the intersection of edges
    l2=L(jj) / (s2(jj)/s1(jj)*c1(jj) + c2(jj));

    xtemp=[-L(jj)/2 0 ; L(jj)/2 0 ; [L(jj)/2 0]+l2*[-c2(jj) s2(jj)] ;  -L(jj)/2 0 ];
    
    % Move the triangle centroid to the origin
    xtemp=xtemp-[mean(xtemp(:,1)) mean(xtemp(:,2))];
    
    % Scale the triangle
    % Original area by Heron's formula
    a=norm(xtemp(1,:)-xtemp(2,:));
    b=norm(xtemp(2,:)-xtemp(3,:));
    c=norm(xtemp(3,:)-xtemp(1,:));
    sp= ( a + b + c )/2;
    orArea=sqrt(sp*(sp-1)*(sp-b)*(sp-c));
    
    scf=sqrt(pi*eqRadii(jj)^2/orArea);
    xtemp=xtemp*scf;
    
    % Random  rotation of the triangle
    theta=2*pi*rand;
    randRot=[cos(theta) -sin(theta); sin(theta) cos(theta)];
    x{jj}=(randRot*xtemp')';
    
end




