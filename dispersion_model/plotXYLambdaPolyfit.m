function plotXYLambdaPolyfit(X, x_field, disparity, disparity_field, varargin)
% PLOTXYLAMBDAPOLYFIT  Plot a polynomial model of dispersion in two or three variables
%
% ## Syntax
% plotXYLambdaPolyfit(...
%     X, x_field, disparity, disparity_field,...
%     lambda, lambda_ref, n_lambda_plot, polyfun...
% )
% plotXYLambdaPolyfit(...
%     X, x_field, disparity, disparity_field,...
%     channel_ref, polyfun...
% )
%
% ## Description
% plotXYLambdaPolyfit(...
%     X, x_field, disparity, disparity_field,...
%     lambda, lambda_ref, n_lambda_plot, polyfun...
% )
%   Creates figures for graphical comparisons of measured dispersion with a
%   polynomial model of dispersion
%
% plotXYLambdaPolyfit(...
%     X, x_field, disparity, disparity_field,...
%     channel_ref, polyfun...
% )
%   Identical operation, but for dispersion measured between colour
%   channels instead of wavelength bands
%
% ## Input Arguments
%
% X -- Data for the first two independent variables (image coordinates)
%   A structure array of the form of the 'stats_real' or 'stats_ideal'
%   output arguments of 'doubleSphericalLensPSF()'. 'X' must have a
%   size of 1 in its third dimension.
%
% x_field -- First two independent variables field
%   A character vector containing the fieldname in 'X' of the data to use
%   for the first two independent variables of the polynomial model.
%   `X(i, j, 1).(x_field)` is expected to be a two-element row vector.
%
% disparity -- Data for the dependent variables (dispersion vectors)
%   A structure of the form of the 'disparity_raw' output argument of
%   'statsToDisparity()'. 'disparity.(name)' must have a size of 1 in its
%   fourth dimension.
%
% disparity_field -- Dependent variables field
%   A character vector containing the fieldname in 'disparity' of the data
%   to use for the dependent variables of the polynomial model.
%   `disparity.(disparity_field)(i, :, j)` is expected to be a two-element
%   row vector, containing the values of the two dependent variables.
%
% lambda -- Data for the third independent variable (wavelength)
%   A vector of values of the third independent variable. `lambda(j)` is
%   the value corresponding to the data in `X(:, j, 1).(x_field)` and
%   `disparity(:, :, j).(disparity_field)`.
%
% lambda_ref -- Reference wavelength
%   Dispersion vectors are calculated relative to image positions for this
%   wavelength. This input argument is only used for plot annotation.
%
% n_lambda_plot -- Wavelength sample count
%   The number of plots to generate for data for individual wavelengths.
%   Wavelengths will be selected from 'lambda' using a procedure which
%   favours even spacing in the spectrum.
%
% channel_ref -- Reference colour channel
%   Dispersion vectors are calculated relative to image positions for the
%   colour channel of this index in the series of colour channels. This
%   input argument is only used for plot annotation.
%
% polyfun -- Polynomial model of dispersion
%   The 'polyfun' output argument of 'xylambdaPolyfit()', which evaluates
%   polynomials of dispersion in X, Y, and lambda, or which evaluates a
%   separate set of polynomials in X and Y for each colour channel.
%
% See also xylambdaPolyfit, statsToDisparity

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created April 18, 2018

nargoutchk(0, 0);
narginchk(6, 8);
if nargin == 7
    error('Unexpected number of input arguments.')
end

sz = size(X);
channel_mode = (nargin == 6);
if channel_mode
    index_ref = varargin{1};
    polyfun = varargin{2};
    n_plot = sz(2);
    lambda = 1:n_plot;
else
    lambda = varargin{1};
    index_ref = varargin{2};
    n_plot = varargin{3};
    polyfun = varargin{4};
end

if channel_mode
    lambda_samples = lambda;
    lambda_samples_ind = 1:n_plot;
else
    lambda_samples = linspace(lambda(1), lambda(end), n_plot);
    lambda_samples_ind = zeros(n_plot, 1);
    for k = 1:n_plot
        [~, lambda_samples_ind(k)] = min(abs(lambda - lambda_samples(k)));
        lambda_samples(k) = lambda(lambda_samples_ind(k));
    end
end

% Individual plots for a sample of the wavelengths, or for all colour
% channels
n_spatial_dim = 2;
xy_sampling = [200 200];
for k = 1:n_plot
    X_unpacked = permute(reshape([X(:, lambda_samples_ind(k)).(x_field)], n_spatial_dim, []), [2 1]);
    lambda_unpacked = repelem(lambda_samples(k), sz(1), 1);
    disparity_unpacked = disparity.(disparity_field)(:, :, lambda_samples_ind(k));
    dataset = [X_unpacked lambda_unpacked disparity_unpacked];

    % Filter NaN values
    dataset = dataset(all(isfinite(dataset), 2), :);
    
    % Evaluate the polynomial model
    max_x = max(dataset(:, 1));
    max_y = max(dataset(:, 2));
    min_x = min(dataset(:, 1));
    min_y = min(dataset(:, 2));
    [x_grid, y_grid] = meshgrid(linspace(min_x, max_x, xy_sampling(1)), linspace(min_y, max_y, xy_sampling(2)));
    dataset_grid = [x_grid(:), y_grid(:), repmat(lambda_samples(k), numel(x_grid), 1)];
    disparity_poly_grid = polyfun(dataset_grid);
    %disparity_poly_grid_x = reshape(disparity_poly_grid(:, 1), size(x_grid));
    %disparity_poly_grid_y = reshape(disparity_poly_grid(:, 2), size(x_grid));
    disparity_poly_points = polyfun(dataset(:, 1:3));
    
    disparity_poly_grid_mag = sqrt(dot(disparity_poly_grid, disparity_poly_grid, 2));
    disparity_poly_grid_mag_matrix = reshape(disparity_poly_grid_mag, size(x_grid));
    disparity_poly_points_mag = sqrt(dot(disparity_poly_points, disparity_poly_points, 2));
    
    disparity_points_mag = sqrt(dot(dataset(:, 4:5), dataset(:, 4:5), 2));
    
    % Visualization
    figure;
    hold on
    s = surf(x_grid, y_grid, disparity_poly_grid_mag_matrix);
    set(s, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    c = colorbar;
    c.Label.String = 'Disparity magnitude';
    %quiver3(x_grid, y_grid, disparity_poly_grid_mag_matrix, disparity_poly_grid_x, disparity_poly_grid_y, zeros(size(x_grid)), 'g');
    quiver3(dataset(:, 1), dataset(:, 2), disparity_poly_points_mag, disparity_poly_points(:, 1), disparity_poly_points(:, 2), zeros(size(disparity_poly_points_mag)), 'r');
    quiver3(dataset(:, 1), dataset(:, 2), disparity_points_mag, dataset(:, 4), dataset(:, 5), zeros(size(disparity_points_mag)), 'g');
    hold off
    xlabel('Image x-coordinate')
    ylabel('Image y-coordinate')
    if channel_mode
        zlabel(sprintf('Magnitude of dispersion wrt Channel %d', index_ref))
    else
        zlabel(sprintf('Magnitude of dispersion wrt \\lambda = %g', index_ref))
    end
    %legend('Polynomial model', 'Polynomial model', 'Polynomial model', 'Measured dispersion');
    legend('Polynomial model', 'Polynomial model', 'Measured dispersion');
    if channel_mode
        title(sprintf('Evaluation of the polynomial model of dispersion for Channel %d', lambda_samples(k)));
    else
        title(sprintf('Evaluation of the polynomial model of dispersion for \\lambda = %g', lambda_samples(k)));
    end
end

% Single plot for all wavelengths
X_unpacked = permute(reshape([X.(x_field)], n_spatial_dim, []), [2 1]);
lambda_unpacked = repelem(lambda, sz(1));
disparity_unpacked = reshape(permute(disparity.(disparity_field), [1 3 2]), [], 2);
if size(lambda_unpacked, 1) < size(lambda_unpacked, 2)
    lambda_unpacked = lambda_unpacked.';
end
dataset = [X_unpacked lambda_unpacked disparity_unpacked];

% Filter NaN values
dataset = dataset(all(isfinite(dataset), 2), :);

% Evaluate the polynomial model
disparity_poly_points = polyfun(dataset(:, 1:3));

% Visualization
figure;
hold on
quiver3(dataset(:, 1), dataset(:, 2), dataset(:, 3), disparity_poly_points(:, 1), disparity_poly_points(:, 2), zeros(size(disparity_poly_points, 1), 1), 'r');
quiver3(dataset(:, 1), dataset(:, 2), dataset(:, 3), dataset(:, 4), dataset(:, 5), zeros(size(disparity_poly_points, 1), 1), 'g');
hold off
xlabel('Image x-coordinate')
ylabel('Image y-coordinate')
if channel_mode
    zlabel('Colour channel index')
else
    zlabel('Wavelength [nm]')
end
legend('Polynomial model', 'Measured dispersion');
title('Evaluation of the polynomial model of dispersion');
    
end