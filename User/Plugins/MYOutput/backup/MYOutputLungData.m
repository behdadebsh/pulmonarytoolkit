classdef MYOutputLungData < PTKPlugin
    % PTKAirways. Plugin for outputing the lung segmentation result and
    % saved as exdata format
    %
    %     This is a plugin for a self-built function of the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     The output image generated by GenerateImageFromResults creates a
    %     colour-coded segmentation image with true airway points shown as blue
    %     and explosion points shown in red.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Output Lung'
        ToolTip = 'Output Lung segmentation result and convert it into exdata'
        Category = 'Export'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results=RunPlugin(dataset,reporting)
            %             if nargin < 2
            %                 reporting = PTKReportingDefault;
            %             end
            
            lungs=dataset.GetResult('PTKLeftAndRightLungs');
            Lung=lungs.RawImage;
            [a1,b1,c1]=size(Lung);
            LeftLungCoor_x=[];RightLungCoor_x=[];
            LeftLungCoor_y=[];RightLungCoor_y=[];
            LeftLungCoor_z=[];RightLungCoor_z=[];
            for i=1:2:c1
                AxLung=Lung(:,:,i);
                [RightRow,RightCol]=find(AxLung==1);
                MaxRightLung=max(RightCol);
                [LeftRow,LeftCol]=find(AxLung==2);
                MinLeftLung=min(LeftCol);
                LeftAndRightBoundry=round((MaxRightLung+MinLeftLung)./2);
                level=graythresh(AxLung);
                AxLung=im2bw(AxLung,level);
                AxLung=imfill(AxLung,'holes'); %% fill the holes
                AxLung=edge(AxLung,'canny'); %% extract the lung boundary
                Lung(:,:,i)=AxLung;
                for j=1:3:a1
                    for k=(LeftAndRightBoundry+1):3:b1
                        if Lung(j,k,i)~=0
                            LeftLungCoor_x=[LeftLungCoor_x,j];
                            LeftLungCoor_y=[LeftLungCoor_y,k];
                            LeftLungCoor_z=[LeftLungCoor_z,i];
                        end
                    end
                end
                for j=1:3:a1
                    for k=1:3:(LeftAndRightBoundry+1)
                        if Lung(j,k,i)~=0
                            RightLungCoor_x=[RightLungCoor_x,j];
                            RightLungCoor_y=[RightLungCoor_y,k];
                            RightLungCoor_z=[RightLungCoor_z,i];
                        end
                    end
                end
            end
            
%             LungDicomImage = PTKLoadImages(dataset.GetImageInfo);
%             [start_crop,end_crop]=MYGetLungROIForCT(LungDicomImage);
%             
            VoxelSize=lungs.VoxelSize;
            OriginalImageSize=lungs.OriginalImageSize;
            start_crop=lungs.Origin;
            LeftLungCoor_x1=(LeftLungCoor_y+start_crop(2)-1).*VoxelSize(2);
            LeftLungCoor_y1=OriginalImageSize(2).*VoxelSize(2)-(OriginalImageSize(1)-(LeftLungCoor_x+start_crop(1)-1)).*VoxelSize(1);
            LeftLungCoor_z1=-(LeftLungCoor_z+start_crop(3)-1).*VoxelSize(3);
            RightLungCoor_x1=(RightLungCoor_y+start_crop(2)-1).*VoxelSize(2);
            RightLungCoor_y1=OriginalImageSize(2).*VoxelSize(2)-(OriginalImageSize(1)-(RightLungCoor_x+start_crop(1)-1)).*VoxelSize(1);
            RightLungCoor_z1=-(RightLungCoor_z+start_crop(3)-1).*VoxelSize(3);
            
            LeftLungCoor=[LeftLungCoor_x1',LeftLungCoor_y1',LeftLungCoor_z1'];
            RightLungCoor=[RightLungCoor_x1',RightLungCoor_y1',RightLungCoor_z1'];
            %% Get the saving path
            data_info=dataset.GetImageInfo;
            full_data_path=data_info.ImagePath;
            data_path_separate=regexp(full_data_path,'/','split');
            Subject_number=data_path_separate{end-3};
            full_path=mfilename('fullpath');
            [path_root, ~, ~] = fileparts(full_path);
            root_path_separate=regexp(full_path,'/','split');
            save_root_path=[];
            root_path_separate=root_path_separate(1:(end-4));
            for m=2:length(root_path_separate)
                save_root_path=strcat(save_root_path,'/',root_path_separate{m});
            end
            save_full_path=strcat(save_root_path,'/Save/LungSegmentationResult/',Subject_number);
            MYWriteExdata('surface_Lefttrimmed.exdata',LeftLungCoor,'surface_Left',10000,save_full_path);
            MYWriteExdata('surface_Righttrimmed.exdata',RightLungCoor,'surface_Right',200000,save_full_path);
            MYWriteIpdata('surface_Lefttrimmed.ipdata',LeftLungCoor,'surface_Left',10000,save_full_path);
            MYWriteIpdata('surface_Righttrimmed.ipdata',RightLungCoor,'surface_Right',200000,save_full_path);
            results=lungs.Copy;
        end
    end
end
