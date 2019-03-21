function [] = NQ_displayImageData (paramsIn, expFolder)
% NQ_displayImageData will display analysis data.
%
% Part of NET-QUANT.
%
%
%
% Pontus Nordenfelt 02/2017


%% ------ Parameters ------- %%
p = paramsIn;


%% ------- Define processing ------%%

[~, metadata] = NQ_loadStruct(expFolder,'metadata');

flags = metadata.flags;

%% ------- Load and display data depending on flags ------%%
%% create figures

%define figure position, size and name
scrSize = get(0,'ScreenSize');
figPosLeft = scrSize(1);
figPosBottom = scrSize(1)+(scrSize(4)-scrSize(4)/3);
figSizeX = scrSize(3)/4;
figSizeY = scrSize(4)/3;

figHan = cell(5,1);
axHan = cell(5,1);

for m=1:5
    figHan{m} = ['f' num2str(m)];
end

%channels
channelList = {...
    p.nucleiName,...
    p.netName,...
    [p.nucleiName ' mask'],...
    [p.netName ' mask'],...
    'overlay'};

%set top row of figures
nrFig_top = 4;


for j = 1:nrFig_top
    figHan{j} = figure('units','pixels','position',...
        [figPosLeft+figSizeX*j-figSizeX figPosBottom*0.85 figSizeX figSizeY],...
        'numbertitle','off','name',channelList{j});axis off;axis tight;
    axHan{j} = axes('Parent',figHan{j}); %Initialize axes and get handle
    set(axHan{j},'LooseInset',get(axHan{j},'TightInset'))
end

%create mid row of figures
nrFig_mid = 1;
if nrFig_mid >0
    for j = 1:nrFig_mid
        figHan{j+4} = figure('units','pixels','position',...
            [figPosLeft+figSizeX*j-figSizeX figPosBottom-figSizeY*1.5 figSizeX figSizeY],...
            'menubar','none','numbertitle','off','name',channelList{j+4});axis off;axis tight;
        axHan{j+4} = axes('Parent',figHan{j+4}); %Initialize axes and get handle
        set(axHan{j+4},'LooseInset',get(axHan{j+4},'TightInset'))
    end
end



if isfield(flags,'NQ_prepareData')
    if flags.NQ_prepareData == 1
        [~, ims] = NQ_loadStruct(expFolder,'ims'); %load images
        
        imshow(ims.channels.(p.nucleiName),[],'Parent',axHan{1}); %Display the imageimshow(ims.channels.(p.nucleiName),[]);
        
        imshow(ims.channels.(p.netName),[], 'Parent',axHan{2});%imshow(ims.channels.(p.netName),[]);
        
    end
    
end

if isfield(flags,'NQ_segmentImages')
    if flags.NQ_segmentImages == 1
        
        [~, masks] = NQ_loadStruct(expFolder,'masks');
        
        %subplot(2,2,3)
        imshow(masks.channels.(p.nucleiName),[],'Parent',axHan{3});
        
        %subplot(2,2,4)
        imshow(masks.channels.(p.netName),[],'Parent',axHan{4});
    end
end

%link axis of windows
linkaxes([axHan{1} axHan{2} axHan{3} axHan{3} axHan{4}],'xy');


if isfield(flags,'NQ_analysis')
    if flags.NQ_analysis == 1
        
        [~, analysis] = NQ_loadStruct(expFolder,'analysis');
        [~, threshold] = NQ_loadStruct([p.targetDir filesep p.controlPath],'threshold');
        
        
        % final labeled image
        L1 = analysis.label.(p.nucleiName);
        L2 = analysis.label.(p.netName);
        bw1 = logical(L1);
        bw2 = logical(L2);
        
        %show nets
        imshow(bw2,[],'Parent',axHan{5});
        hold on
        %show nuclei
        spy(bw1,'c');
        
        %display numbers
        cellStats=analysis.cellStats;
        cellCount=numel(cellStats.CellNr(:));
        positiveCells(cellCount) = false;
        
        for k = 1:cellCount
            c = cellStats.Centroid{k};
            netcell=false; %assume it is not a net-positive cell
            if ~isnan(c)
                text(c(1), c(2), sprintf('%d', cellStats.CellNr(k)), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle');
                if cellStats.Area(k)>threshold.medianNetSize %net area larger than average control cell
                    if cellStats.Area(k)>...
                            threshold.medianNetSize*p.areaInc %net area increase over average cell
                        netcell=true;
                    end
                    if cellStats.CircularityDNA(k)<p.deformationInc
                        netcell=true;
                    end
                    if cellStats.ratioArea(k)>p.ratioInc
                        netcell=true;
                    end
                    
                end
                if netcell==true
                    plot(c(1)+10,c(2)-10,'r*', 'MarkerSize',15);
                end
            end
            positiveCells(k) = netcell;
        end
        hold off
        
        
        %determine cells above threshold
        percentageNet = sum(positiveCells)/cellCount*100;
        
        msgbox ({['cell count: ' num2str(cellCount) newline ...
            'net positive cells: ' num2str(percentageNet) '%']},'Results');
        
        %link axis of windows
        linkaxes([axHan{1} axHan{2} axHan{3} axHan{3} axHan{4} axHan{5}],'xy');

        
    end
end

end