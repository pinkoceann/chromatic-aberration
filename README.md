# Simultaneous Demosaicing and Chromatic Aberration Correction through Spectral Reconstruction
**Started Spring 2017**

**University of Alberta, Department of Computing Science**

## Code Contributors
- Bernard Llanos, supervised by Dr. Y.-H. Yang

## Description

- Calibration of lateral chromatic aberration by image registration or
  keypoint localization
- Correction of lateral chromatic aberration by image warping, where the warping
  is performed on either colour channels, or spectral bands
- Conversion of raw colour-filter array images to RGB or spectral images
  for chromatic aberration correction
- Utility functions
  - Spectral-to-colour conversion
  - Colour space conversion
  - Resampling spectral information
- Batch image processing and output image evaluation, for running the algorithms
  on image datasets
- Scripts for visualizing and analyzing the results

## Environment
- MATLAB R2018b was used for development, but other MATLAB releases will likely
  work.
- Code has been run under both Ubuntu 18.04 and Windows 10.

## Dependencies

### MathWorks MATLAB toolbox dependencies
- Required toolboxes:
  - Computer Vision System Toolbox
  - Image Processing Toolbox
  - Optimization Toolbox
  - Statistics and Machine Learning Toolbox
- The following MathWorks MATLAB toolboxes are likely required, but by small
  portions of the codebase:
  - Curve Fitting Toolbox
  - Mapping Toolbox
- The following MathWorks MATLAB toolboxes are possibly required:
  - Global Optimization Toolbox
- The Parallel Computing Toolbox is an optional dependency, and can be removed
  by replacing `parfor` with `for` in all files where `parfor` appears.
- A full list of dependencies for individual files can be determined as
  described at https://www.mathworks.com/help/matlab/matlab_prog/identify-dependencies.html

### Third-party dependencies
- All third-party dependencies are either optional, or are easily ommitted
  through minor modifications to the codebase.
- Third-party dependencies should be added to the MATLAB path, after being
  set-up according to their own documentation.

#### Colour correction
- Authors: Han Gong et al.
- Location: https://github.com/hangong/ch
- Provides: Colour homography and root-polynomial colour correction algorithms,
  corresponding to several publications
- Required by:
  - [data_analysis/CalibrateColorCorrection.m]()
  - [data_analysis/ColorCorrection.m]()

#### Revisiting Cross-channel Information Transfer for Chromatic Aberration Correction (ICCV 2017)
- Authors: Tiancheng Sun, Yifan Peng, and Wolfgang Heidrich
- Location: https://github.com/evanypeng/ICCV2017_RevisitCCIT_code
- Provides: An uncalibrated method for correcting chromatic aberration
- Optional dependency, used by [evaluation/RunOnDataset.m]() only when enabled
  in [evaluation/SetAlgorithms.m]()
  - Parameters for the method were tuned using [data_analysis/TuneSunEtAl2017.m]().

#### Blind Deconvolution Using a Normalized Sparsity Measure (CVPR 2011)
- Authors: Dilip Krishnan, Terence Tay, and Rob Fergus
- Location: https://dilipkay.wordpress.com/blind-deconvolution
- Provides: An uncalibrated method for image deblurring
- Optional dependency, used by [data_analysis/ShowPatches.m](), when directed
  - Parameters for the method were tuned using [data_analysis/TuneSunEtAl2017.m]().

#### Very fast Mutual Information between two images
- Authors: Giangregorio Generoso
- Location: https://www.mathworks.com/matlabcentral/fileexchange/36538-very-fast-mutual-information-betweentwo-images
- Provides: A function to calculate mutual information
- Required by:
  - [data_analysis/TuneSunEtAl2017.m]()
  - [evaluation/evaluateRGB.m]()
  - [evaluation/evaluateSpectral.m]()
- Easily omitted if necessary

#### OpenEXR-Bindings for MATLAB
- Authors: Manuel Leonhardt
- Location: https://github.com/skycaptain/openexr-matlab (actually retrieved
  from a fork: https://github.com/KAIST-VCLAB/openexr-matlab)
- Provides: Functions for reading and writing OpenEXR files
- Required by [utilities/loadImage.m](), only when working with OpenEXR files.

#### Adaptive Residual Interpolation for Color and Multispectral Image Demosaicking (Sensors 2017)
- Authors: Yusuke Monno, Daisuke Kiku, Masayuki Tanaka and Masatoshi Okutomi
- Location: http://www.ok.sc.e.titech.ac.jp/res/DM/RI.html
- Provides: An RGB image demosaicing method
- Optional dependency, used by [evaluation/RunOnDataset.m]() only when enabled
  in [evaluation/SetAlgorithms.m](). Also used by [data_analysis/TuneSunEtAl2017.m]().

## Setup
- Add all folders and subfolders to the MATLAB path, excluding [.git/]() and [deprecated/]().

## Basic usage instructions
- Files starting with capital letters are MATLAB scripts, which can be used
  as described in their documentation comments.
- Remaining files are MATLAB functions called by the scripts.
  There are a few MATLAB functions used for ad-hoc analysis for which no scripts
  have yet been created to call them.

## Tips
- Raw colour-filter array images as used in this codebase are truly raw. No gamma
  or colour correction has been applied to them. In other demosaicing codebases,
  I have seen the input raw images simulated from full-colour RGB images that
  have already been gamma/colour-corrected, where the simulation process does
  not account for the gamma/colour correction.

## Detailed description of the codebase
- Use the MATLAB `help` command to view the 'Contents.m' files describing the codebase,
  as explained in MATLAB's documentation, "Create Help Summary Files --- Contents.m".
- A high-level description of the top-level folders is as follows:
  - 'aberration_correction': Chromatic aberration correction, by image warping, or by
    global optimization accounting for image warping and mosaicing.
  - 'aberration_data': Simulation of spectral image to colour image conversion, and
    lateral chromatic aberration (as image warping). Synthetic image generation.
  - 'calibration_data': Tools for creating chromatic aberration calibration patterns
    that can be printed for calibrating real cameras.
  - 'data_analysis': Scripts for producing human-viewable results and analysis
    of the output of other code in the repository. In particular, there are
    scripts for creating colour-corrected images. There are also scripts created
    for tangential or one-time experiments.
  - 'deprecated': Unmaintained code, that is no longer called by the programs
    in other folders. Code in this folder is present for archival purposes only.
  - 'disk_fitting': Disk keypoint-based calibration of lateral chromatic aberration,
    following the approach of Rudakova and Monasse 2014.
  - 'dispersion_model': All other code for calibrating models of lateral chromatic
    aberration that does not explicitly involve disk keypoints.
  - 'evaluation': Quantitative evaluation of image reconstruction and chromatic
    aberration correction. There are scripts for running many image estimation
    algorithms, including the third-party methods listed above, on dataset
    of images.
  - 'raw_image_preprocessing': Code for creating datasets of images, including
    high-dynamic range images and multispectral images. There are also functions
    for sampling and demosaicing raw colour-filter array images. Note that
    the code in this folder was developed for the particular apparatus that I
    used, and may not be useful for other image capturing setups.
  - 'ray_tracing': Code for simulating and analyzing point spread functions for
    point light sources at different distances and angular positions from a double
    convex lens. This folder is largely present for archival purposes.
    The code it contains was developed for preliminary research investigations,
    and was not used to generate results for any publications.
  - 'sampling': Functions for resampling and numerical integration of signals,
    inspired by sampling theory.
  - 'sensor': Code for saving various camera spectral response functions in the
    format used by the rest of the codebase.
  - 'utilities': Miscellaneous helper functions, such as for data input/output,
    text processing, and geometry calculations.
  - 'vignetting': Calibration and application of models for making image
    intensities more uniform in regions that are subject to lens
    vignetting or to non-uniform lighting.

## References

### Note
- The following is a list of the references corresponding to sources of
  code or ideas. This list is the union of the more specific lists of
  references provided in individual code files in this repository.
  It is not a full list of all of the works examined during research
  project.

### References list

B. Arad, O. Ben-Shahar, and R. Timofte, “NTIRE 2018 challenge on
spectral reconstruction from RGB images,” in IEEE Conference on
Computer Vision and Pattern Recognition (CVPR) Workshops, Jun.
2018.

“Standard Practice for Computing the Colors of Objects by Using the
CIE System,” ASTM International, West Conshohocken, PA, Standard,
2017. doi: 10.1520/E0308-17.

S.-H. Baek, I. Kim, D. Gutierrez, and M. H. Kim, “Compact single-shot
hyperspectral imaging using a prism,” ACM Transactions on Graphics,
vol. 36, no. 6, 2017. doi: 10.1145/3130800.3130896.

M. Belge, M. E. Kilmer, and E. L. Miller, “Efficient determination of
multiple regularization parameters in a generalized l-curve framework,”
Inverse Problems, vol. 18, no. 4, pp. 1161–1183, 2002.
doi: 10.1088/0266-5611/18/4/314.

M. Born and E. Wolf, Principles of optics, 4. ed. Oxford: Pergamon
Press, 1970, isbn: 9780080139876.

S. Boyd, N. Parikh, E. Chu, B. Peleato, and J. Eckstein, “Distributed
optimization and statistical learning via the alternating direction method
of multipliers,” Foundations and Trends in Machine Learning, vol. 3,
no. 1, pp. 1–122, Jan. 2011. doi: 10.1561/2200000016.

J. Brauers and T. Aach, “Geometric calibration of lens and filter distortions
for multispectral filter-wheel cameras,” IEEE Transactions on Image Processing,
vol. 20, no. 2, pp. 496–506, 2011. doi: 10.1109/TIP.2010.2062193.

J. Brauers, N. Schulte, and T. Aach, “Multispectral filter-wheel cam-
eras: Geometric distortion model and compensation algorithms,” IEEE
Transactions on Image Processing, vol. 17, no. 12, pp. 2368–2380, 2008.
doi: 10.1109/TIP.2008.2006605.

M. Ceccarelli, M. di Bisceglie, C. Galdi, G. Giangregorio, S.L. Ullo,
"Image Registration Using Non–Linear Diffusion", IGARSS 2008.

I. Choi, D. S. Jeon, G. Nam, D. Gutierrez, and M. H. Kim, “High-
quality hyperspectral reconstruction using a spectral prior,” ACM Trans-
actions on Graphics, vol. 36, no. 6, 2017. doi: 10.1145/3130800.3130810.

M. M. Darrodi, G. Finlayson, T. Goodman, and M. Mackiewicz, “Refer-
ence data set for camera spectral sensitivity estimation,” Journal of the
Optical Society of America A: Optics and Image Science, and Vision,
vol. 32, no. 3, pp. 381–391, 2015. doi: 10.1364/JOSAA.32.000381.

D. Eberly. (Jun. 19, 2016). Geometric Tools. version 3.0.0, [Online].
Available: https://www.geometrictools.com (visited on 07/06/2018).

G. D. Finlayson, M. MacKiewicz, and A. Hurlbert, “Color correction
using root-polynomial regression,” IEEE Transactions on Image Pro-
cessing, vol. 24, no. 5, pp. 1460–1470, 2015.
doi: 10.1109/TIP.2015.2405336.

G. Finlayson, H. Gong, and R. B. Fisher, “Color homography: Theory
and applications,” IEEE Transactions on Pattern Analysis and Ma-
chine Intelligence, vol. 41, no. 1, pp. 20–33, 2019.
doi: 10.1109/TPAMI.2017.2760833.

D.H. Foster. (2018). Tutorial on Transforming Hyperspectral Images to
RGB Colour Images, [Online].
Available: http://personalpages.manchester.ac.uk/staff/d.h.foster/Tutorial_HSI2RGB/Tutorial_HSI2RGB.html
(visited on 06/05/2018).

J. W. Goodman, Introduction to Fourier optics, 3rd ed. Englewood,
Colorado: Roberts & Company, 2005, isbn: 0974707724.

T. Hastie, R. Tibshirani, and J. H. Friedman, The elements of statistical
learning: data mining, inference, and prediction. New York: Springer,
2009, p. 745, isbn: 9780387848570.

B. Horn, Robot vision. Cambridge, Massachusetts: MIT Press, 1986,
p. 509, isbn: 0262081598.

D. Kiku, Y. Monno, M. Tanaka, and M. Okutomi, “Beyond color dif-
ference: Residual interpolation for color image demosaicking,” English,
IEEE Transactions on Image Processing, vol. 25, no. 3, pp. 1288–1300, 2016.
doi: 10.1109/TIP.2016.2518082.

D. Krishnan, T. Tay, and R. Fergus, “Blind deconvolution using a nor-
malized sparsity measure,” in IEEE Conference on Computer Vision
and Pattern Recognition (CVPR), 2011, pp. 233–240.
doi: 10.1109/CVPR.2011.5995521.

B.J. Lindbloom. (2017). Spectral Power Distribution of a CIE D-Illuminant,
[Online].
Available: http://www.brucelindbloom.com
(visited on 06/04/2018).

B.J. Lindbloom. (2017). Computing XYZ From Spectral Data,
[Online].
Available: http://www.brucelindbloom.com
(visited on 06/11/2018).

F. Mannan and M. S. Langer, “Blur calibration for depth from defo-
cus,” in Canadian Conference on Computer and Robot Vision (CRV),
J. Guerrero, Ed., Institute of Electrical and Electronics Engineers Inc.,
Jun. 2016, pp. 281–288. doi: 10.1109/CRV.2016.62.

E. Martinec. (2008). Noise, dynamic range and bit depth in digital SLR, [Online].
Available: http://theory.uchicago.edu/∼ejm/pix/20d/tests/noise/
(visited on 06/30/2017).

Y. Monno, D. Kiku, M. Tanaka, and M. Okutomi, “Adaptive residual
interpolation for color and multispectral image demosaicking,” Sensors
(Switzerland), vol. 17, no. 12, 2017. doi: 10.3390/s17122787.

A. Mosleh, P. Green, E. Onzon, I. Begin, and J. M. P. Langlois, “Cam-
era intrinsic blur kernel estimation: A reliable framework,” in IEEE
Conference on Computer Vision and Pattern Recognition (CVPR), IEEE
Computer Society, Jun. 2015, pp. 4961–4968. doi: 10.1109/CVPR.2015.7299130.

J. Mustaniemi, J. Kannala, and J. Heikkila, “Parallax correction via disparity
estimation in a multi-aperture camera,” Machine Vision and Applications,
vol. 27, no. 8, pp. 1313–1323, 2016. doi: 10.1007/s00138-016-0773-7.

R. M. H. Nguyen, D. K. Prasad, and M. S. Brown, “Training-based
spectral reconstruction from a single RGB image,” in The European
Conference on Computer Vision (ECCV), Sep. 2014.
doi: 10.1007/978-3-319-10584-0_13.

J.-I. Park, M.-H. Lee, M. D. Grossberg, and S. K. Nayar, “Multispectral
imaging using multiplexed illumination,” in IEEE International Con-
ference on Computer Vision, 2007. doi: 10.1109/ICCV.2007.4409090.

D. Pascal. (2016). The ColorChecker Pages, [Online].
Available: http://www.babelcolor.com/colorchecker.htm
(visited on 06/04/2018).

M. Pharr and G. Humphreys, Physically Based Rendering: From The-
ory to Implementation, ser. Morgan Kaufmann series in interactive 3D
technology. Burlington, Massachusetts: Elsevier Science, 2010, isbn:
9780123750792.

M. N. Polyanskiy. (2019). Refractive index database, [Online].
Available: https://refractiveindex.info. (visited on 07/16/2019).

J. Qiu and H. Xu, “Camera response prediction for various capture
settings using the spectral sensitivity and crosstalk model,” Applied
Optics, vol. 55, no. 25, pp. 6989–6999, 2016.
doi: 10.1364/AO.55.006989.

E. Reinhard, G. Ward, S. Pattanaik, and P. Debevec, High dynamic
range imaging. San Francisco, Calif.: Morgan Kaufmann, 2006, isbn:
9780125852630.

V. Rudakova and P. Monasse, “Precise correction of lateral chromatic
aberration in images,” in Image and Video Technology, 2014, pp. 12–22.

Y. Song, D. Brie, E.-H. Djermoune, and S. Henrot, “Regularization
parameter estimation for non-negative hyperspectral image deconvolu-
tion,” IEEE Transactions on Image Processing, vol. 25, no. 11, pp. 5316–
5330, 2016. doi: 10.1109/TIP.2016.2601489.

R. Sumner. (2014). Processing RAW Images in MATLAB, [Online].
Available: http://rcsumner.net/raw_guide/RAWguide.pdf
(visited on 07/16/2019).

T. Sun, Y. Peng, and W. Heidrich, “Revisiting cross-channel infor-
mation transfer for chromatic aberration correction,” in IEEE Inter-
national Conference on Computer Vision (ICCV), 2017, pp. 3268–3276.
doi: 10.1109/ICCV.2017.352.

H. Tan, X. Zeng, S. Lai, Y. Liu, and M. Zhang, “Joint demosaicing
and denoising of noisy bayer images with ADMM,” in International
Conference on Image Processing (ICIP), Sep. 2018, pp. 2951–2955.
doi: 10.1109/ICIP.2017.8296823.

G. Wahba, Spline models for observational data. Philadelphia, Pa.:
Society for Industrial and Applied Mathematics SIAM, 1990, isbn:
9781611970128.

E.W. Weisstein. (2019). Sphere Point Picking, From MathWorld--A Wolfram
Web Resource, [Online].
Available: http://mathworld.wolfram.com/SpherePointPicking.html
(visited on 07/16/2019).