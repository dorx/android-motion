function n = rotateVecToVec(x, u, v, p)
%ROTATEVECTOVEC Rotate vector x defined by the rotation of vector u to v
%
% The rotation implied by the rotation of u to v (along the plane of u,v)
% is applied to x. The p value is a real value describing how much to
% rotate x, where p = 1 it would rotate x to match the full rotation of u
% to v (i.e. if x = u and p = 1, the result would be v itself). p can be
% set to any real value.

% Check for special case of u=v, in which case there is no rotation
if u == v
    n = x;
    return
end

axis = cross(u, v);
axis = axis / norm(axis);

theta = acos(dot(u, v) / (norm(u) * norm(v))) * p;

n= x*cos(theta)+dot(x, axis)*(1-cos(theta))*axis+cross(axis,x)*sin(theta);


end

