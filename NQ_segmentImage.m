function [mask,maskedImage] = NQ_segmentImage(paramsIn, im, method, sensitivity, iterations, minArea, watershedOn)
%segmentImage segments image using different options
%  [mask,MASKEDIMAGE] = segmentImage(IM) segments image IM using different options. 
%   The final segmentation is returned in
%  MASK and a masked image is returned in MASKEDIMAGE.



%method:        'adaptive', 'global', 'edge' or 'Chan-Vese'
%iterations:    default 100
%minArea:       default 100

% Pontus Nordenfelt 02/2017
%----------------------------------------------------

p = paramsIn;

%make sure image is correct class
im = cast(im,'uint16');

switch method
    case 'adaptive'
        % Threshold image - adaptive threshold
        mask = imbinarize(im, 'adaptive', 'Sensitivity', sensitivity, 'ForegroundPolarity', 'bright');
        
    case 'global'
        % Threshold image - global threshold
        mask = imbinarize(im);
        
        



    case 'edge'
        % Initialize segmentation with Otsu's threshold
        mask = imbinarize(im);
        
        % expand mask before active contour if edge method is used
        if strcmp(method,'Edge')
            se = strel('disk',10);
            mask = imdilate(mask, se);
        end
        
        % Evolve segmentation
        mask = activecontour(im, mask, iterations, method);

        
    case 'Chan-Vese'
        % Initialize segmentation with Otsu's threshold
        mask = imbinarize(im);
        
        % Evolve segmentation
        mask = activecontour(im, mask, iterations, method);

        
end


% Remove objects touching the border;
mask = imclearborder(mask);

% Fill holes
mask = imfill(mask, 'holes');

% Filter components by area
mask = bwareafilt(mask, [minArea inf]);

% Watershed to separate touching objects
if watershedOn==1
    %remove small foreground objects on complemented mask
    mask = ~bwareaopen(~mask, 10);
    
    %iniitial distance transform
    D=bwdist(~mask);
    %complement the transform
    D=-D;
    %force pixels that don't belong to objects to be at Inf
    D(~mask) = Inf;
    
    %filter out tiny local minima using imextendedmin and then modify the distance transform so that no minima occur at the filtered-out locations.
    bw3 = imextendedmin(D,2);
    D2 = imimposemin(D,bw3);
    
    %perform watershed
    L = watershed (D2);
    mask(L==0)=0;
end


% Form masked image from input image and segmented image.
maskedImage = im;
maskedImage(~mask) = 0;
end
