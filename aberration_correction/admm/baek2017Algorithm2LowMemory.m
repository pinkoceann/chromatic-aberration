function in = baek2017Algorithm2LowMemory(weights, options, in, varargin)
% BAEK2017ALGORITHM2LOWMEMORY  Run ADMM (loosely) as in Algorithm 2 of Baek et al. 2017
%
% ## Usage
% This is a version of 'baek2017Algorithm2()' which does not allocate any
% large arrays. All large arrays are passed in using its `in` input
% argument. The two input arguments `in` and `weights` are expected to be
% generated by 'initBaek2017Algorithm2LowMemory()'.
% 
% ## Syntax
% in = baek2017Algorithm2LowMemory(weights, options, in, [, verbose])
%
% ## Description
% in = baek2017Algorithm2LowMemory(weights, options, in, [, verbose])
%   Estimate a latent RGB or hyperspectral image `I` from dispersion in
%   the input RAW image `in.J`.
%
% ## Input Arguments
%
% weights -- Regularization weights
%   `weights(1)` is the 'alpha' weight on the regularization of the spatial
%   gradient of the image in Equation 6 of Baek et al. 2017. `weights(2)`
%   is the 'beta' weight on the regularization of the spectral gradient of
%   the spatial gradient of the image in Equation 6 of Baek et al. 2017.
%   `weights(3)` is a weight on the regularization of the spatial Laplacian of
%   the image, as used in Song et al. 2016.
%
%   If all elements of `weights` are zero, and `options.nonneg` is `false`,
%   this function will throw an error, in contrast to
%   'baek2017Algorithm2()', as image estimation in this case is expected to
%   be handled by the caller.
%
%   `weights` is expected to be normalized by the lengths of the
%   vectors being weighted, as done by 'initBaek2017Algorithm2LowMemory()'
%
% options -- Options and small parameters
%   A structure with the following fields:
%   - 'rho': A three or four-element vector containing penalty parameters
%     used in the ADMM framework. The first three elements correspond to
%     regularization terms (refer to the documentation of `weights`). The
%     fourth element is a penalty parameter for a non-negativity constraint
%     on the solution, and is only required if the 'nonneg' field is
%     `true`.
%   - 'maxit': A two-element vector. The first element contains the maximum
%     number of iterations to use with MATLAB's 'pcg()' function during the
%     I-minimization step of the ADMM algorithm. The second element of
%     `maxit` contains the maximum number of ADMM iterations to perform.
%   - 'norms': A three-element logical vector, corresponding to the
%     regularization terms (refer to the documentation of `weights`). Each
%     element specifies whether to use the L1 norm (`true`) or an L2 norm
%     (`false`) of the corresponding regularization penalty vector. If some
%     elements of 'norms' are `false`, the ADMM iterations are simplified
%     by eliminating slack variables. If all elements are `false`, and
%     'nonneg' is `false`, then ADMM reduces to a least-squares solution.
%   - 'nonneg': A Boolean scalar specifying whether or not to enable a
%     non-negativity constraint on the estimated image. If `true`, 'rho'
%     must have four elements.
%   - 'tol': A two-element vector containing convergence tolerances. The
%     first element is the tolerance value to use with MATLAB's 'pcg()'
%     function, such as when solving the I-minimization step of the ADMM
%     algorithm. The second element is the relative tolerance for the ADMM
%     algorithm, as explained in Section 3.3.1 of Boyd et al. 2011.
%   - 'varying_penalty_params': If empty (`[]`), the penalty parameters
%     passed in 'rho' will be fixed across all ADMM iterations. Otherwise,
%     'varying_penalty_params' is a three-element vector containing the
%     parameters 'tau_incr', 'tau_decr', and 'mu', respectively, in
%     equation 3.13 of Boyd et al. 2011. In this case, the penalty
%     parameters in the ADMM iterations will vary, so as to speed up
%     convergence. Refer to Section 3.4.1 of Boyd et al. 2011 for a full
%     explanation.
%
% in -- Preallocated intermediate data and results
%   In the following, `I` is the estimated latent image in vectorized form,
%   with a length of N. `J` is the vectorized form of the input RAW image,
%   `in.J`, with a length of M.
%
%   `in` is a structure with the following fields:
%   - 'M_Omega_Phi': A matrix of size M x N projecting `I` onto `J`.
%   - 'M_Omega_Phi_J': The product `M_Omega_Phi.' * J`.
%   - 'G': A cell vector with the same length as `weights`, containing the
%     regularization operators corresponding to each of the regularization
%     terms. `G{1}` is `G_xy`, the spatial gradient operator. `G{2}` is
%     `G_lambda_xy`, the spectral-spatial mixed second order gradient
%     operator. `G{3} is `L_xy`, the spatial Laplacian operator.
%   - 'G_T': A cell vector containing the transposed versions of the
%     elements of 'G'.
%   - 'G_2': A cell vector, where `G_2{i} = G_T{i} * G{i}`.
%   - 'I': The vectorized form of the estimated latent image. 'I' must
%     already be initialized, as its initial value is used to start
%     iterative image estimation.
%   - 'J': The vectorized form of the input RAW image. A vector of length M.
%   - 'b': The right-hand side vector in the I-minimization step of ADMM. A
%     vector of length N.
%   - 'A': An N x N matrix which is the left-hand side matrix in the
%     I-minimization step of ADMM.
%   - 'A_const': A partial computation of 'A' which is independent of the
%     ADMM penalty parameters.
%   - 'I_A': An identity matrix with the same dimensions as 'A'.
%   - 'g': If `options.nonneg` is `true`, then 'g' is a cell vector with a
%     length one greater than the length of 'G', containing the results of
%     applying each operator in 'G' to `I`. If `options.nonneg` is `false`,
%     then 'g' has one additional element which is a copy of `I`.
%   - 'Z': A version of 'g' updated by soft thresholding and non-negativity
%     constraint enforcement, as appropriate.
%   - 'Z_prev': The version of 'Z' from the previous ADMM iteration.
%   - 'Y': A cell vector with the same format as 'g', containing the ADMM
%     dual variables.
%   - 'U': A cell vector with the same format as 'g', containing the scaled
%     ADMM dual variables.
%   - 'R': The subtraction of 'Z' from 'g'.
%   - 'absolute_tol': The absolute tolerance value for the ADMM algorithm, as
%     explained in Section 3.3.1 of Boyd et al. 2011.
%
%   Note that if elements of `weights` are zero, the corresponding elements
%   of many of the above fields are not needed. Likewise, the elements of
%   `options.norms` determine how some of the fields are computed, and
%   whether all of their elements are needed.
%
%   `in` can be initialized by 'initBaek2017Algorithm2LowMemory()', which
%   will also perform some error checking.
%
% verbose -- Verbosity flag
%   If `true`, console output will be displayed to show the progress of the
%   iterative optimization.
%
% ## Output Arguments
%
% in -- Updated intermediate data and results
%   An updated version of the `in` input argument. The `in.I` is the
%   vectorized form of the estimated latent image.
%
% ## Notes
% - In constrast to 'baek2017Algorithm2()', estimated image is spatially
%   registered with the input image (as when 'baek2017Algorithm2()' is
%   called with its `options.add_border` input argument set to `false`.
%
% ## References
%
% This function implements Algorithm 2 in the first set of supplemental
% material of the following article:
%
%   Baek, S.-H., Kim, I., Gutierrez, D., & Kim, M. H. (2017). "Compact
%     single-shot hyperspectral imaging using a prism." ACM Transactions
%     on Graphics (Proc. SIGGRAPH Asia 2017), 36(6), 217:1–12.
%     doi:10.1145/3130800.3130896
%
% Depending on the options passed, this function also implements variants of the
% algorithm: L2 priors instead of L1 priors, an extra prior on the image spatial
% Laplacian, and a non-negativity constraint. I implemented the non-negativity
% constraint by adding an extra term to the ADMM x-minimization step, and an
% additional z-minimization and dual update step. This is different from the
% constrained optimization examples in Boyd et. al. 2011, sections 4.2.5 and
% 5.2, but I think it matches the format given at the start of Chapter 5.
%
% The Laplacian energy is one of the penalty terms used by:
%
%   Song, Y., Brie, D., Djermoune, E.-H., & Henrot, S.. "Regularization
%     Parameter Estimation for Non-Negative Hyperspectral Image
%     Deconvolution." IEEE Transactions on Image Processing, vol. 25, no.
%     11, pp. 5316-5330, 2016. doi:10.1109/TIP.2016.2601489
%
% A non-negativity constraint was used in (among other works):
%
%   Park, J.-I., Lee, M.-H., Grossberg, M. D., & Nayar, S. K. (2007).
%     "Multispectral Imaging Using Multiplexed Illumination." In 2007 IEEE
%     International Conference on Computer Vision (ICCV).
%     doi:10.1109/ICCV.2007.4409090
%
% For more information on ADMM (Alternating Direction Method of
% Multipliers), read:
%
%   Boyd, S, et al.. "Distributed Optimization and Statistical Learning via
%     the Alternating Direction Method of Multipliers." Foundations and
%     Trends in Machine Learning, vol. 3, no. 1, pp. 1-122, 2011.
%     doi:10.1561/2200000016
%
% ## Future Work
%
% There are several modifications and expansions which may improve the
% performance of ADMM:
% - Section 3.4.1 of Boyd et al. 2011, "Varying Penalty Parameter"
%   - Now activated by a non-empty `options.varying_penalty_params` vector.
%   - Further refinement may be possible by "taking into account the relative
%    magnitudes of [the primal and dual convergence thresholds]."
% - Section 4.3.2 of Boyd et al. 2011, "Early Termination"
%
% See also initBaek2017Algorithm2LowMemory, baek2017Algorithm2, penalties 

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created October 8, 2018

    function inner(two)
        in.b = in.M_Omega_Phi_J;
        for q = 1:n_priors
            if (weights(q) ~= 0) && norms(q)
                in.b = in.b + (rho(q) / 2) * in.G_T{q} * (in.Z{q} - in.U{q});
            end
        end
            
        if nonneg
            in.b = in.b + (rho(end) / 2) * (in.Z{end} - in.U{end});
        end
        
        if two
            in.A = in.A_const;
            for q = 1:n_priors
                if (weights(q) ~= 0) && norms(q)
                    in.A = in.A + (rho(q) / 2) * in.G_2{q};
                end
            end

            if nonneg
                in.A = in.A + (rho(end) / 2) * in.I_A;
            end
        end
    end

nargoutchk(1, 1);
narginchk(3, 4);

% Enable output of a '.mat' file containing information for examining
% convergence
save_iterations = false;

if ~isempty(varargin)
    verbose = varargin{1};
else
    verbose = false;
end

% Validate and parse input arguments
n_priors = 3;
nonneg_ind = 4;
enabled_weights = (weights ~= 0);
nonneg = options.nonneg;
if all(~enabled_weights) && ~nonneg
    error('At least one element of `weights` must be positive, or `options.nonneg` must be `true`.');
end
norms = options.norms;
% Don't use ADMM to optimize priors given zero weight
norms(~enabled_weights) = false;
rho = options.rho;

vary_penalty_parameters = false;
if ~isempty(options.varying_penalty_params)
    vary_penalty_parameters = true;
    tau_incr = options.varying_penalty_params(1);
    if tau_incr <= 1
        error('The `tau_incr` parameter, `options.varying_penalty_params(1)`, must be greater than one.');
    end
    tau_decr = options.varying_penalty_params(2);
    if tau_decr <= 1
        error('The `tau_decr` parameter, `options.varying_penalty_params(2)`, must be greater than one.');
    end
    mu = options.varying_penalty_params(3);
    if mu <= 1
        error('The `mu` parameter, `options.varying_penalty_params(3)`, must be greater than one.');
    end
end

% Initialization
len_I = length(in.I);
in.M_Omega_Phi_J = in.M_Omega_Phi.' * in.J;

% Select the appropriate algorithm variant
if all(~norms) && ~nonneg
    if(verbose)
        fprintf(...
            'Computing a regularized least squares solution with tolerance %g for up to %d iterations...\n',...
            options.tol(1), options.maxit(1)...
        );
    end
    inner(true);
    [ in.I, flag, relres, iter_pcg ] = pcg(...
        in.A, in.b, options.tol(1), options.maxit(1), [], [], in.I...
    );
    if(verbose)
        fprintf('\tLeast-squares result: PCG (flag = %d, relres = %g, iter = %d)\n',...
            flag, relres, iter_pcg...
        );
    end
else
    % Perform ADMM
    if(verbose)
        fprintf('Computing an iterative solution using ADMM...\n');
    end
        
    active_constraints = [norms, nonneg];
    n_Z = find(active_constraints, 1, 'last');
    
    if save_iterations
        n_bands = len_I / length(in.J);
        if n_bands ~= round(n_bands)
            error('The ratio between the number of elements in `I` and `J` is not an integer.');
        end
        center_px_iter = zeros(options.maxit(2), n_bands);
        center_px_ind = ceil(length(in.J) * ((1:n_bands) - 0.5));
        pcg_n_iter = zeros(options.maxit(2), 1);
        pcg_relres_iter = zeros(options.maxit(2), 1);
        pcg_flag_iter = zeros(options.maxit(2), 1);
        R_norm_iter = zeros(options.maxit(2), n_Z);
        S_norm_iter = zeros(options.maxit(2), n_Z);
        epsilon_pri_iter = zeros(options.maxit(2), n_Z);
        epsilon_dual_iter = zeros(options.maxit(2), n_Z);
        changed_penalty_parameters = false(options.maxit(2), n_Z);
    end
    
    % Initialization
    len_Z = zeros(n_Z, 1);
    R_norm = zeros(n_Z, 1);
    S_norm = zeros(n_Z, 1);
    epsilon_pri = zeros(n_Z, 1);
    epsilon_dual = zeros(n_Z, 1);
    
    for z_ind = 1:n_Z
        if active_constraints(z_ind)
            if z_ind == nonneg_ind
                in.Z{z_ind} =  in.I;
            else
                in.Z{z_ind} = in.G{z_ind} * in.I;
            end
            len_Z(z_ind) = length(in.Z{z_ind});
            in.U{z_ind} = zeros(len_Z(z_ind), 1);
        end
    end

    % Iteration
    inner(true);
    soft_thresholds = weights ./ rho(1:n_priors);

    for iter = 1:options.maxit(2)
        % Optimization
        [ in.I, flag, relres, iter_pcg ] = pcg(...
            in.A, in.b, options.tol(1), options.maxit(1), [], [], in.I...
        );
        if(verbose)
            fprintf('%d:    PCG (flag = %d, relres = %g, iter = %d)\n',...
                iter, flag, relres, iter_pcg...
                );
        end
        if save_iterations
            pcg_n_iter(iter) = iter_pcg;
            pcg_relres_iter(iter) = relres;
            pcg_flag_iter(iter) = flag;
        end
        
        converged = true;
        
        for z_ind = 1:n_Z
            if ~active_constraints(z_ind)
                continue;
            end
            if z_ind == nonneg_ind
                in.g{z_ind} = in.I;
            else
                in.g{z_ind} = in.G{z_ind} * in.I;
            end
            in.Z_prev{z_ind} = in.Z{z_ind};
            in.Z{z_ind} = in.g{z_ind} + in.U{z_ind};
            if z_ind == nonneg_ind
                % See Section 5.2 of Boyd et al. 2011.
                in.Z{z_ind}(in.Z{z_ind} < 0) = 0;
            else
                % See Section 6.3 of Boyd et al. 2011.
                % Soft thresholding
                in.Z{z_ind}(in.Z{z_ind} > 0) = max(in.Z{z_ind}(in.Z{z_ind} > 0) - soft_thresholds(z_ind), 0);
                in.Z{z_ind}(in.Z{z_ind} < 0) = min(in.Z{z_ind}(in.Z{z_ind} < 0) + soft_thresholds(z_ind), 0);
            end
            % See Section 3.1.1 of Boyd et al. 2011.
            in.R{z_ind} = in.g{z_ind} - in.Z{z_ind};
            in.U{z_ind} = in.U{z_ind} + in.R{z_ind};
            
            % Calculate residuals
            R_norm(z_ind) = norm(in.R{z_ind});
            if z_ind == nonneg_ind
                S_norm(z_ind) = norm(rho(z_ind) * (in.Z{z_ind} - in.Z_prev{z_ind}));
            else
                S_norm(z_ind) = norm(rho(z_ind) * in.G_T{z_ind} * (in.Z{z_ind} - in.Z_prev{z_ind}));
            end
            
            % Calculate stopping criteria
            % See Section 3.3.1 of Boyd et al. 2011.
            epsilon_pri(z_ind) = sqrt(len_Z(z_ind)) * in.absolute_tol +...
                options.tol(2) * max([norm(in.g{z_ind}), norm(in.Z{z_ind})]);
            in.Y{z_ind} = rho(z_ind) * in.U{z_ind};
            if z_ind == nonneg_ind
                epsilon_dual(z_ind) = sqrt(len_I) * in.absolute_tol +...
                    options.tol(2) * norm(in.Y{z_ind});
            else
                epsilon_dual(z_ind) = sqrt(len_I) * in.absolute_tol +...
                    options.tol(2) * norm(in.G_T{z_ind} * in.Y{z_ind});
            end
            converged = converged &&...
                (R_norm(z_ind) < epsilon_pri(z_ind) && S_norm(z_ind) < epsilon_dual(z_ind));
            
            if(verbose)
                fprintf('%d:    Residuals %d (R1_norm = %g, S1_norm = %g)\n',...
                    iter, z_ind, R_norm(z_ind), S_norm(z_ind)...
                    );
                fprintf('%d:    Stop Crit. %d (e_p1 = %g, e_d1 = %g)\n',...
                    iter, z_ind, epsilon_pri(z_ind), epsilon_dual(z_ind)...
                );
            end
            if save_iterations
                R_norm_iter(iter, z_ind) = R_norm(z_ind);
                S_norm_iter(iter, z_ind) = S_norm(z_ind);
                epsilon_pri_iter(iter, z_ind) = epsilon_pri(z_ind);
                epsilon_dual_iter(iter, z_ind) = epsilon_dual(z_ind);
            end
        end
        
        if save_iterations
            center_px_iter(iter, :) = reshape(in.I(center_px_ind), 1, []);
        end

        % Check against stopping criteria
        if converged
            break;
        end

        if vary_penalty_parameters
            changed = false(n_Z, 1);
            for z_ind = 1:n_Z
                if ~active_constraints(z_ind)
                    continue;
                end
                % Equation 3.13 in Section 3.4.1 of Boyd et al. 2011
                if R_norm(z_ind) > mu * S_norm(z_ind)
                    rho(z_ind) = rho(z_ind) * tau_incr;
                    changed(z_ind) = true;
                elseif S_norm(z_ind) > mu * R_norm(z_ind)
                    rho(z_ind) = rho(z_ind) / tau_decr;
                    changed(z_ind) = true;
                end
                if changed(z_ind)
                    in.U{z_ind} = in.Y{z_ind} ./ rho(z_ind);
                end
            end
            soft_thresholds = weights ./ rho(1:n_priors);
            inner(any(changed));
            if save_iterations
                changed_penalty_parameters(iter, :) = changed.';
            end
        else
            inner(false);
        end
    end

    if verbose
        if converged
            fprintf('Convergence after %d iterations.\n', iter);
        else
            fprintf('Maximum number of iterations, %d, reached without convergence.\n', iter);
        end
    end
    if save_iterations
        save(...
            sprintf('saveIterations_bands%d_datetime_%s.mat', n_bands, num2str(now)),...
            'n_bands', 'center_px_iter', 'center_px_ind', 'pcg_n_iter', 'pcg_relres_iter',...
            'pcg_flag_iter', 'R_norm_iter', 'S_norm_iter', 'epsilon_pri_iter',...
            'epsilon_dual_iter', 'changed_penalty_parameters', 'iter', 'converged'...
        );
    end
end

end