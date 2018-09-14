%% Set Fixed Parameters
% Set values of parameters for image correction that seldomly need to be
% changed.
%
% ## Usage
%   Modify the parameters in the code below, as desired. This script exists
%   just to deduplicate code, and will be called by other scripts.
%
%   Some parameters can be given multiple values (indexed by row). Some
%   scripts will iterate through all rows, whereas others will just use the
%   first row of a parameter's values.
%
% ## Implementation Notes
% - When modifying this file, remember to update `parameters_list`.
% - Run this script after setting custom parameters in the calling script,
%   in order for the correct value of `parameters_list` to be generated.
%   The calling script must initialize `parameters_list` with its custom
%   parameter variable names.

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created July 27, 2018

%% List of parameters to save with results
if ~exist('parameters_list', 'var')
    error('`parameters_list` should be initialized prior to running SetFixedParameters.m');
end
parameters_list = [parameters_list, {
    'bayer_pattern',...
    'bands_script',...
    'bands_interp_method',...
    'downsampling_factor',...
    'add_border',...
    'baek2017Algorithm2Options',...
    'rho',...
    'weights',...
    'int_method',...
    'patch_sizes',...
    'paddings',...
    'selectWeightsOptions',...
    'selectWeightsGridOptions',...
    'trainWeightsOptions'...
    }];

%% Image parameters

% Colour-filter pattern
bayer_pattern = 'gbrg';

%% Hyperspectral image estimation parameters

% Override the wavelengths or colour channel indices at which to evaluate
% the model of dispersion, if desired.
bands = 430:10:650;
bands_script = bands;

% Interpolation method used when resampling colour space conversion data
bands_interp_method = 'linear';

% Downsampling factor to apply to the estimated latent images relative to
% the input images. If empty (`[]`), downsampling will not occur.
downsampling_factor = 1;

% Whether to expand the latent image relative to the input image to cover
% all undistorted coordinates from the input image. This is the
% `add_border` input argument.
add_border = false;

% ## Options for baek2017Algorithm2() (Alternating Direction Method of Multipliers)

% Whether to make the spectral gradient the same size as the image. This is
% the `full_GLambda` input argument.
baek2017Algorithm2Options.full_GLambda = false;

% Penalty parameters in ADMM, the `rho` input argument.
% Sample values seem to be in the range 1-10 (see pages 89, 93, and 95 of
% Boyd et al. 2011)
rho = [ 1, 1, 1, 1 ];

% Weights on the two prior terms, the `weights` input argument.
% Baek et al. (2017) used [1e-5, 0.1]
weights = [
    1e-2, 1e-2, 1e-2;
    1e-3, 1e-3, 1e-3
];

% Convergence tolerances in ADMM, the `tol` input argument.
%
% Reasonable values for the third element are 10^-4 to 10^-3 (page 21 of
% Boyd et al. 2011).
baek2017Algorithm2Options.tol = [ 1e-5, 1e-5, 1e-5 ];

% Maximum number of inner and outer iterations, the `maxit` input argument
baek2017Algorithm2Options.maxit = [ 500, 500 ];

% Parameters for adaptively changing the penalty parameters for improved
% convergence speed. (Disable adaptive penalty parameter variation by
% setting this option to an empty array.)
baek2017Algorithm2Options.varying_penalty_params = [2, 2, 10];

% Types of norms to use on the prior terms
baek2017Algorithm2Options.norms = [true, true, true];

% Whether to apply a non-negativity constraint (in which case, `rho` must
% have three elements)
baek2017Algorithm2Options.nonneg = true;

% Integration method to use for colour calculations
%
% If the latent space consists of wavelength bands, use this type of
% numerical integration in 'channelConversionMatrix()'. (Otherwise, a value
% of 'none' will automatically be used instead.)
int_method = 'trap';

% ## Options for patch-wise image estimation

% Every combination of rows of `patch_sizes` and elements of `paddings`
% will be tested.
% If `patch_sizes` is empty only whole image estimation may be performed
patch_sizes = [ % Each row contains a (number of rows, number of columns) pair
   30 30;
]; 
paddings = 10;

% ## Options for selecting regularization weights

selectWeightsOptions.patch_size = patch_sizes(1, :);

selectWeightsOptions.enabled_weights = logical(weights(1, :));

trainWeightsOptions = selectWeightsOptions;

% Whether or not to enforce 'minimum_weights' and 'maximum_weights' given
% in this same options structure
selectWeightsOptions.clip_weights = true;

% Minimum values to use for regularization weights (or to use to set the
% origin of the minimum distance function in case the data fitting matrix
% is singular)
selectWeightsOptions.minimum_weights = eps * ones(1, size(weights, 2));

% Maximum values to use for regularization weights
selectWeightsOptions.maximum_weights = 1e10 * ones(1, size(weights, 2));

selectWeightsGridOptions = selectWeightsOptions;

% Maximum and minimum number of grid search iterations
selectWeightsGridOptions.n_iter = [50, 20];

selectWeightsGridOptions.tol = 1e-6;

% Type of scaling
selectWeightsGridOptions.scaling = 'normalized';

selectWeightsOptions.method = 'fixed-point-safe';

% Maximum number of fixed-point (1) and line search (2) iterations
selectWeightsOptions.maxit = [100, 100];

% Relative convergence criteria for the fixed-point iterative algorithm and
% for the inner line search
selectWeightsOptions.tol = [1e-4, 1e-2];

trainWeightsOptions.n_iter = selectWeightsGridOptions.n_iter;

% Minimum values to use for regularization weights
trainWeightsOptions.minimum_weights = eps * ones(1, size(weights, 2));

% Maximum values to use for regularization weights
trainWeightsOptions.maximum_weights = 1e10 * ones(1, size(weights, 2));

trainWeightsOptions.tol = 1e-6;

% Border to exclude from image patches before calculating error
baek2017Algorithm2Options.l_err_border = [paddings(1), paddings(1)];
trainWeightsOptions.border = paddings(1);

% ## Debugging Flags
baek2017Algorithm2Verbose = true;
selectWeightsVerbose = true;
selectWeightsGridVerbose = true;
trainWeightsVerbose = true;