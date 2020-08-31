function [x, error_progression] = DLS3(l,u, I, score, iter,TOL)

%%%%MY OWN TEST-- NOT USED%%%%%%%%%
% Random projections using upper and lower bounds
% Choose the lowest score point as anchor.
% Reduced incidence matrix & stop condition

%Inputs:
    % [l,u]:     Lower/upper bound on relative measurements
    % I:         Incidence matrix (mxn)
    % score:     Score column (nx1)
    % iter:      Max number of iterations
    % Tol:       stop condition precision: eps

    
%Output:
    % x: low-dimensional data point output

% Initialization of v and z (line2 from Alg.1)
[~,minInd] = min(score); % find the index of lowest score point
I(:,minInd) = [];% reduced incidence matrix
[m,n] = size(I);
% m = size(I,1);
% n = size(I,2);
x = zeros(n, 1);
%z = I*x;
% The mean square error per iteration

%calculate column probability
p2 = sum(I.^2, 1);
p2 = full(p2);
p2 = p2/sum(p2);
s = randsample(n,iter,true,p2); % Pick nodes according to degrees, s is a vector contains #max_it nodes pick. (line.9) 


fprintf('Start of DLS algorithm, # of iterations: %d\n', iter);
error_progression = zeros(1, iter);

I_inv = pseudoinverse(I);
P = eye(m) - I*I_inv;

for cnt = 1 : iter
    
    % Display some info every 1000 iterations
     if mod(cnt, 1) == 0, fprintf('DLS, iter # = %d/ %d)\n', cnt, iter); end
     error = (1/sqrt(n))*norm(I'*(I*x - proj_l_u(I*x,l,u)));
     error_progression(cnt) = error;
     if mod(cnt, 1000) == 0 &&  error < TOL %norm(I*x-(y-z))/(norm(I,'fro')*norm(x)) < TOL && norm(I'*z)/(norm(I,'fro')^2*norm(x))< TOL
        fprintf('DLS stopped at %d\n', cnt);
        break;
     end

    edge_index = randsample(find(I(:,s(cnt))),1); % Pick an edge adjacent to selected node s uniformly at random (line. 10)
     I_node = full(I(:, s(cnt)));
    I_edge = full(I(edge_index, :));
    z = proj_l_u(I*x,l,u);
    z = P*z;
    %z = z - (1 / norm( I_node)^2 ) * (I_node' * z) * I_node;
     % update edge variables 
    
    x = x - (1 / norm( I_edge)^2 )*(I_edge*x - proj_l_u(I_edge*x,l(edge_index),u(edge_index)) +z(edge_index))* I_edge';  % update nodal variables. (line.16 - 21)
    %x = x - (1 / norm( I_edge)^2 )* (I_edge*x - proj_l_u(I_edge*x,l(edge_index),u(edge_index)))*I_edge';
    
    
end
x = [x(1:(minInd-1));0;x(minInd:end)];
fprintf('End of DLS algorithm\n');

